package Uncertainties
  
  import DAE;
  import Absyn;
  import BackendDAE;
  import BackendVariable;
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
  import BackendDump;
  import ExpressionSimplify;
  //import MathematicaDump;
  import BackendDAEEXT;
  
  
  public function dumpComponents "function: dumpComponents
  author: PA
 
  Prints the blocks of the BLT sorting on stdout.
"
  input list<list<Integer>> l;
algorithm 
  print("Blocks\n");
  print("=======\n");
  dumpComponents2(l, 1);
end dumpComponents;

protected function dumpComponents2 "function: dumpComponents2
  author: PA
 
  Helper function to dumpComponents.
"
  input list<list<Integer>> inIntegerLstLst;
  input Integer inInteger;
algorithm 
  _:=
  matchcontinue (inIntegerLstLst,inInteger)
    local
      Integer ni,i_1,i;
      list<String> ls;
      String s;
      list<Integer> l;
      list<list<Integer>> lst;
    case ({},_) then (); 
    case ((l :: lst),i)
      equation         
        print("{");
        ls = List.map(l, intString);
        s = stringDelimitList(ls, ", ");
        print(s);
        print("}\n");
        i_1 = i + 1;
        dumpComponents2(lst, i_1);
      then
        ();
  end matchcontinue;
end dumpComponents2;
  
  
  public function modelEquationsUC
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  //input Boolean addDummy "if true, add a dummy state";
  //input Option<SimulationSettings> inSimSettingsOpt;
  //input Absyn.FunctionArgs args "labels for remove terms";
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.SymbolTable outInteractiveSymbolTable;

algorithm
  (outCache,outValue,outInteractiveSymbolTable):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inFileNamePrefix)
    local
      String filenameprefix,file_dir,resstr;
      list<SCode.Element> p_1;
      DAE.DAElist dae;
      list<Env.Frame> env;
      BackendDAE.BackendDAE dlow,dlow_1,indexed_dlow,indexed_dlow_1;
      Absyn.ComponentRef a_cref;
      list<String> libs;
      Interactive.SymbolTable st;
      Absyn.Program p,ptot;
      //DAE.Exp fileprefix;
      Env.Cache cache;
      DAE.FunctionTree funcs;
      Real timeSimCode, timeTemplates, timeBackend, timeFrontend;
      BackendDAE.IncidenceMatrix m,mt;
      array<Integer> ass1,ass2;
      BackendDAE.Value n;
      list<list<Integer>> comps, uccomps;
      Integer varCount;
      BackendDAE.Variables vars,kvars;
      list<Integer> eqnIndexList, varIndexList, allVarIndexList, refineVarIndexList, elimVarIndexList,approximatedEquations,equationToExtract;
      BackendDAE.EquationArray eqns,ieqns;
      array<BackendDAE.MultiDimEquation> arrEqns;
      array<DAE.Algorithm> algs;
      list<BackendDAE.Equation> eqnLst,ieqnLst;
      list<BackendDAE.EqSystem> eqsyslist;      
            
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p)),filenameprefix)
      equation
        
        print("* Calling  modelEquationsUC\n");
        // calculate stuff that we need to create SimCode data structure 
        System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);
        //(cache,Values.STRING(filenameprefix),SOME(_)) = Ceval.ceval(cache,env, fileprefix, true, SOME(st),NONE(), msg);
        ptot = Dependency.getTotalProgram(className,p);
        p_1 = SCodeUtil.translateAbsyn2SCode(ptot);
        (cache,env,_,dae) = Inst.instantiateClass(cache,InnerOuter.emptyInstHierarchy,p_1,className);
        timeFrontend = System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);
        System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);
        dae = DAEUtil.transformationsBeforeBackend(cache,dae);
        funcs = Env.getFunctionTree(cache);
        
        print("* Flatten ok\n");
        
        dlow = BackendDAECreate.lower(dae,funcs,true);
        print("* Lower ok\n");
        
        
        dlow_1 = BackendDAEUtil.getSolvedSystem(cache, env, dlow, funcs,SOME({"removeFinalParameters", "removeEqualFunctionCalls","partitionIndependentBlocks", "expandDerOperator"}), NONE(), NONE());
        print("*** Lowered: \n");
        BackendDump.dump(dlow_1);
        print("*** end Lowered: \n");
        
       
        BackendDAE.DAE(eqsyslist as (BackendDAE.EQSYSTEM(_,_,SOME(m),SOME(mt),BackendDAE.MATCHING(ass1,ass2,_))::_),_/*BackendDAE.SHARED()*/) = dlow_1;
        
        print("** Number of EQSYSTEM: ");
        print(intString(listLength(eqsyslist)));
        print("\n");
        
        n = arrayLength(m);
        BackendDAEEXT.initLowLink(n);
        BackendDAEEXT.initNumber(n);
        (_,_,comps) = BackendDAETransform.strongConnectMain(m, mt, ass1, ass2, n, 0, 1, {}, {});
        
        print("All components:\n");
        dumpComponents(comps);
        
        
        // Extract equations for uncertainty computations.          
        uccomps = extractEquationsForUC(dlow_1, m, comps);
        
        print("UC components:\n");
        dumpComponents(uccomps);
        
        // Get a subsystem with only the equations and variables considered for uncertainty computations.          
        eqnIndexList = getEquationsInBlocks(uccomps);
        print("Equations with uncertainty variables: "); 
        print(stringDelimitList(List.map(eqnIndexList,intString)," , "));
        print("\n"); 
        
        
        
        // get equations with annotation ApproximatedEquation
        approximatedEquations=getEquationsWithApproximatedAnnotation(dlow_1);
        print("Approximated Equations: "); 
        print(stringDelimitList(List.map(approximatedEquations,intString)," , "));
        print("\n");
        
        equationToExtract = List.setDifference(eqnIndexList, approximatedEquations);
        varIndexList = getVariablesInBlocks(m, uccomps);
        
        
        (dlow_1 as BackendDAE.DAE(eqs = BackendDAE.EQSYSTEM(orderedVars = vars as BackendDAE.VARIABLES(numberOfVars = varCount))::_)) = getSubSystemDaeForVars(equationToExtract, varIndexList, dlow_1);
        // Eliminate variables whose uncertain attribute is not set to Uncertainty.refine.          
        allVarIndexList = List.intRange(varCount);
        refineVarIndexList = getUncertainRefineVariableIndexes(vars, allVarIndexList);
        elimVarIndexList = List.setDifferenceOnTrue(allVarIndexList, refineVarIndexList, intEq);
        
        print("Variables with uncertainty attibute: "); 
        print(stringDelimitList(List.map(refineVarIndexList,intString)," , "));
        print("\n");
        
        print("Variables to eliminate: "); 
        print(stringDelimitList(List.map(elimVarIndexList,intString)," , "));
        print("\n");
        
        
        (dlow_1 as BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns)::_,BackendDAE.SHARED(knownVars=kvars,initialEqs=ieqns,arrayEqs=arrEqns,algorithms=algs))) = eliminateVariablesDAE(elimVarIndexList,dlow_1);

        eqnLst = BackendDAEUtil.equationList(eqns);
        ieqnLst = BackendDAEUtil.equationList(ieqns);
        
        print("*** Uncertainties extracted: \n");
        BackendDump.dump(dlow_1);

        //resstr = MathematicaDump.dumpMmaDAEStr((vars,kvars,eqnLst,ieqnLst,arrEqns,algs));     
        
           
        resstr="";
      then
        (cache,Values.STRING(resstr),st);
    case (_,_,className,_,_)
      equation        
        true = Flags.isSet(Flags.FAILTRACE);
        resstr = Absyn.pathStringNoQual(className);
        resstr = stringAppendList({"SimCode: The model ",resstr," could not be translated"});
        Error.addMessage(Error.INTERNAL_ERROR, {resstr});
      then
        fail();
  end matchcontinue;
end modelEquationsUC;

protected function getEquationsWithApproximatedAnnotation
   input BackendDAE.BackendDAE dae;
   output list<Integer> outEqs;
algorithm
  outEqs:=match(dae)
     local
       Integer n;
       BackendDAE.EquationArray orderedEqs;
       list<Integer> ret;
    case(BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedEqs=orderedEqs)::_,_))
      equation
        ret=getEquationsWithApproximatedAnnotation2(BackendDAEUtil.equationList(orderedEqs),0);
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
    case(BackendDAE.EQUATION(_,_,DAE.SOURCE(comment=comment)))
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


public function eliminateVariablesDAE
"
  author: Daniel Hedberg, 2011-01
  
  Eliminates the specified variables between the given set of equations.
"
  input list<Integer> elimVarIndexList;
  input BackendDAE.BackendDAE indae;
  output BackendDAE.BackendDAE outDae;
algorithm
  outDae := matchcontinue(elimVarIndexList, indae)
    local
      BackendDAE.BackendDAE dae;
      BackendDAE.Variables vars,vars_1,kvars,kvars_1,extVars;
	    BackendDAE.EquationArray eqns,reqns,ieqns;
	    BackendDAE.EqSystem syst;
	    BackendDAE.Shared shared;
	    //EventInfo ei;
	    //ComplexEquations ce,ice;
	    //ExternalObjectClasses extObjCls;
	    HashTable.HashTable s;
	    //MultiDimEquation arr_md_eqns,iarr_md_eqns;
	   // DAE.Algorithm algarr,ialgarr;
	    //list<IfEquation> ifeqns,iifeqns;
	    HashTable.HashTable crefDouble;
      BackendDAE.IncidenceMatrix m;
	    //IfEquation arr_ifeqns,arr_iifeqns;
	    HashTable.HashTable movedvars_1;
	    list<BackendDAE.Equation> seqns,eqnLst,ieqnLst;
	    BackendVarTransform.VariableReplacements repl;
     // Functions funcs;
     // Real t1,t2;

    case(elimVarIndexList,dae as BackendDAE.DAE((syst as BackendDAE.EQSYSTEM(orderedEqs=eqns,orderedVars=vars))::_,(shared as BackendDAE.SHARED(knownVars=kvars,initialEqs=ieqns)))) equation
      ieqnLst = BackendDAEUtil.equationList(ieqns);
      eqnLst = BackendDAEUtil.equationList(eqns);
      crefDouble = findArraysPartiallyIndexed(eqnLst);      
      //print("partially indexed crs:"+&Util.stringDelimitList(Util.listMap(crefDouble,Exp.printComponentRefStr),",\n")+&"\n");
      repl = BackendVarTransform.emptyReplacements();

      (m,_) = BackendDAEUtil.incidenceMatrix(syst, shared, BackendDAE.NORMAL()); 
      (eqnLst,seqns,movedvars_1,repl) = eliminateVariablesDAE2(eqnLst,1,vars,kvars,HashTable.emptyHashTable(),repl,crefDouble,m,elimVarIndexList,false);
      //Debug.fcall("dumprepl",BackendVarTransform.dumpReplacements,repl);

      dae = setDaeEqns(dae,BackendDAEUtil.listEquation(eqnLst),false);
      //dae = setDaeSimpleEqns(dae,listEquation(listAppend(equationList(reqns),seqns)));
      dae = replaceDAElow(dae,repl,NONE(),false);  
      (vars_1,kvars_1) = moveVariables(BackendVariable.daeVars(syst),BackendVariable.daeKnVars(shared),movedvars_1); 
      dae = setDaeVars(dae,vars_1);
      dae = setDaeKnownVars(dae,kvars_1);

/*      
      Debug.fcall("dumprepldae",print," removed "+&intString(listLength(seqns))+&" eqns \n");
      Debug.fcall2("dumprepldae",dump,dae,false);  
      Debug.fcall("dumprepldae",print,"removeSimpleEquationsDAE repl : ");
      Debug.fcall("dumprepldae", BackendVarTransform.dumpReplacements, repl);   */   
    then dae;
  end matchcontinue;
end eliminateVariablesDAE;


public function setDaeEqns "set the equations of a dae
public function setEquations 
"
  input BackendDAE.BackendDAE dae;
  input BackendDAE.EquationArray eqns;
  input Boolean initEqs "if true, set initialEquations instead of ordered equations";
  output BackendDAE.BackendDAE odae;
algorithm
  odae := matchcontinue(dae,eqns,initEqs)
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
    BackendDAE.AliasVariables aliasVars "mappings of alias-variables to real-variables"; // added asodja 2010-03-03
    BackendDAE.EquationArray initialEqs "initialEqs ; Initial equations" ;
    BackendDAE.EquationArray removedEqs "these are equations that cannot solve for a variable. for example assertions, external function calls, algorithm sections without effect" ;
    array<BackendDAE.MultiDimEquation> arrayEqs "arrayEqs ; Array equations" ;
    array<DAE.Algorithm> algorithms "algorithms ; Algorithms" ;
    BackendDAE.EventInfo eventInfo "eventInfo" ;
    BackendDAE.ExternalObjectClasses extObjClasses "classes of external objects, contains constructor & destructor";
    BackendDAE.BackendDAEType backendDAEType "indicate for what the BackendDAE is used"; 
    
    case(BackendDAE.DAE(
      (syst as BackendDAE.EQSYSTEM(orderedVars=orderedVars,orderedEqs=orderedEqs,m=m,mT=mT,matching=matching))::systList,
      (shared as BackendDAE.SHARED(knownVars=knownVars,externalObjects=externalObjects,aliasVars=aliasVars,initialEqs=initialEqs,
                                   removedEqs=removedEqs,arrayEqs=arrayEqs,algorithms=algorithms,eventInfo=eventInfo,
                                   extObjClasses=extObjClasses,backendDAEType=backendDAEType))),eqns,false) 
    equation
       syst = BackendDAE.EQSYSTEM(orderedVars,eqns,m,mT,matching);                              
    then
       BackendDAE.DAE(syst::systList,shared); 
    
    case(BackendDAE.DAE(
      (syst as BackendDAE.EQSYSTEM(orderedVars=orderedVars,orderedEqs=orderedEqs,m=m,mT=mT,matching=matching))::systList,
      (shared as BackendDAE.SHARED(knownVars=knownVars,externalObjects=externalObjects,aliasVars=aliasVars,initialEqs=initialEqs,
                                   removedEqs=removedEqs,arrayEqs=arrayEqs,algorithms=algorithms,eventInfo=eventInfo,
                                   extObjClasses=extObjClasses,backendDAEType=backendDAEType))),eqns,true) 
    equation
       shared = BackendDAE.SHARED(knownVars,externalObjects,aliasVars,eqns,removedEqs,arrayEqs,algorithms,eventInfo,extObjClasses,backendDAEType);                              
    then
       BackendDAE.DAE(syst::systList,shared); 
       
  end matchcontinue;
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
    BackendDAE.AliasVariables aliasVars "mappings of alias-variables to real-variables"; // added asodja 2010-03-03
    BackendDAE.EquationArray initialEqs "initialEqs ; Initial equations" ;
    BackendDAE.EquationArray removedEqs "these are equations that cannot solve for a variable. for example assertions, external function calls, algorithm sections without effect" ;
    array<BackendDAE.MultiDimEquation> arrayEqs "arrayEqs ; Array equations" ;
    array<DAE.Algorithm> algorithms "algorithms ; Algorithms" ;
    BackendDAE.EventInfo eventInfo "eventInfo" ;
    BackendDAE.ExternalObjectClasses extObjClasses "classes of external objects, contains constructor & destructor";
    BackendDAE.BackendDAEType backendDAEType "indicate for what the BackendDAE is used"; 
  
    case(BackendDAE.DAE(
      (syst as BackendDAE.EQSYSTEM(orderedVars=orderedVars,orderedEqs=orderedEqs,m=m,mT=mT,matching=matching))::systList,
      (shared as BackendDAE.SHARED(knownVars=knownVars,externalObjects=externalObjects,aliasVars=aliasVars,initialEqs=initialEqs,
                                   removedEqs=removedEqs,arrayEqs=arrayEqs,algorithms=algorithms,eventInfo=eventInfo,
                                   extObjClasses=extObjClasses,backendDAEType=backendDAEType))),repl,func,replaceVariables) 
    equation
       orderedVars = BackendDAEUtil.listVar(replaceVars(BackendDAEUtil.varList(orderedVars),repl,func,replaceVariables));
       orderedEqs = BackendDAEUtil.listEquation(BackendVarTransform.replaceEquations(BackendDAEUtil.equationList(orderedEqs),repl));
       syst = BackendDAE.EQSYSTEM(orderedVars,orderedEqs,m,mT,matching);
       shared = BackendDAE.SHARED(knownVars,externalObjects,aliasVars,initialEqs,removedEqs,arrayEqs,algorithms,eventInfo,extObjClasses,backendDAEType);                              
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
  outVarLst := matchcontinue(invarLst,repl,func,replaceName)
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      Option<DAE.Exp> bindExp;
      list<BackendDAE.Var> varLst;  
       
    case({},repl,func,replaceName) then {};
    case(v::varLst,repl,func,replaceName as true) equation
      cr = BackendVariable.varCref(v);
      bindExp = varBindingOpt(v);
      bindExp = replaceExpOpt(bindExp,repl,func);
      bindExp = applyOptionSimplify(bindExp);      
      (DAE.CREF(cr,_),_) = BackendVarTransform.replaceExp(DAE.CREF(cr, DAE.T_REAL_DEFAULT),repl,func);
      v = setVarCref(v,cr);
      v = setVarBindingOpt(v,bindExp);
      varLst = replaceVars(varLst,repl,func,replaceName);
    then v::varLst;
    
    case(v::varLst,repl,func,replaceName as false) equation
      bindExp = varBindingOpt(v);
      bindExp = replaceExpOpt(bindExp,repl,func);
      bindExp = applyOptionSimplify(bindExp);
      v = setVarBindingOpt(v,bindExp);          
      varLst = replaceVars(varLst,repl,func,replaceName);
    then v::varLst;
  end matchcontinue;
end replaceVars;


public function setVarBindingOpt "
  author: PA
 
  sets the optional binding of a variable.
"
  input BackendDAE.Var inVar;
  input Option<DAE.Exp> bindExp;
  output BackendDAE.Var outVar;
algorithm 
  outVar:=
  matchcontinue (inVar,bindExp)
    local
      DAE.ComponentRef name,origCr;
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind ;
      Option<Values.Value> bindval;
      DAE.InstDims ad;
      Integer indx;
      DAE.ElementSource source "origin of variable" ;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> cmt;
      DAE.Flow fl;
      DAE.Stream str;
    case (BackendDAE.VAR(name,kind,dir,tp,bind,bindval,ad,indx,source,attr,cmt,fl,str),bindExp) then 
      BackendDAE.VAR(name,kind,dir,tp,bindExp,bindval,ad,indx,source,attr,cmt,fl,str); 
  end matchcontinue;
end setVarBindingOpt;

public function setVarCref "
  author: PA
 
  sets the ComponentRef of a variable.
"
  input BackendDAE.Var inVar;
  input DAE.ComponentRef cr;
  output BackendDAE.Var outVar;
algorithm 
  outVar:=
  matchcontinue (inVar,cr)
    local
      DAE.ComponentRef name,origCr;
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.Type tp;
      Option<DAE.Exp> bind ;
      Option<Values.Value> bindval;
      DAE.InstDims ad;
      Integer indx;
      DAE.ElementSource source "origin of variable" ;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> cmt;
      DAE.Flow fl;
      DAE.Stream str;
    case (BackendDAE.VAR(name,kind,dir,tp,bind,bindval,ad,indx,source,attr,cmt,fl,str),cr) then 
      BackendDAE.VAR(cr,kind,dir,tp,bind,bindval,ad,indx,source,attr,cmt,fl,str); 
  end matchcontinue;
end setVarCref;

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
  outExp := matchcontinue (inExp,repl,funcOpt)
  local DAE.Exp e;
    case(NONE(),_,_) then NONE();
    case(SOME(e),repl,funcOpt)
      equation
        /* TODO: Propagate this boolean? */
        (e,_) = BackendVarTransform.replaceExp(e,repl,funcOpt);
      then SOME(e);
  end matchcontinue;
end replaceExpOpt;


public function varBindingOpt "function: varBindingOpt
author: PA

returns the binding expression option of a variable"
input BackendDAE.Var v;
output Option<DAE.Exp> exp;
algorithm
  exp := matchcontinue(v)
    case(BackendDAE.VAR(bindExp = exp)) then exp;
  end matchcontinue;
end varBindingOpt;

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
  (outVariables1,outVariables2):=
  matchcontinue (inVariables1,inVariables2,hashTable)
    local
      list<BackendDAE.Var> lst1,lst2,lst1_1,lst2_1;
      BackendDAE.Variables v1,v2,vars,knvars,vars1,vars2;
      HashTable.HashTable mvars;
    case (vars1,vars2,mvars)
      equation 
        lst1 = BackendDAEUtil.varList(vars1);
        lst2 = BackendDAEUtil.varList(vars2);
        (lst1_1,lst2_1) = moveVariables2(lst1, lst2, mvars);
        v1 = BackendDAEUtil.emptyVars();
        v2 = BackendDAEUtil.emptyVars();
        //vars = addVarsNoUpdCheck(lst1_1, v1);
        vars = BackendVariable.addVars(lst1_1, v1);
        //knvars = addVarsNoUpdCheck(lst2_1, v2);
        knvars = BackendVariable.addVars(lst2_1, v2);
      then
        (vars,knvars);
  end matchcontinue;
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
      DAE.Flow flowPrefix;
      HashTable.HashTable mvars;
    case ({},knvars,_) then ({},knvars); 
    case (((v as BackendDAE.VAR(varName = cr,flowPrefix = flowPrefix)) :: vs),knvars,mvars)
      equation 
        _ = BaseHashTable.get(cr,mvars) "alg var moved to known vars" ;
        (vs_1,knvars_1) = moveVariables2(vs, knvars, mvars);
      then
        (vs_1,(v :: knvars_1));
    case (((v as BackendDAE.VAR(varName = cr,flowPrefix = flowPrefix)) :: vs),knvars,mvars)
      equation 
        failure(_ = BaseHashTable.get(cr,mvars)) "alg var not moved to known vars" ;
        (vs_1,knvars_1) = moveVariables2(vs, knvars, mvars);
      then
        ((v :: vs_1),knvars_1);
  end matchcontinue;
end moveVariables2;

protected function eliminateVariablesDAE2
"
  author: Daniel Hedberg, 2011-01

	Finds the variables in elimVarIndexList that can be eliminated in between
	the given set of equations. Returns a set of variable replacements that can
	be used to replace the variables in the equations that are left
"
  input list<BackendDAE.Equation> eqns;
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
  matchcontinue (eqns,eqnIndex,vars,knvars,mvars,repl,inDoubles,m,elimVarIndexList,failCheck)
    local
      BackendDAE.Variables vars,knvars;
      HashTable.HashTable states;
      HashTable.HashTable mvars,mvars_1,mvars_2;
      BackendVarTransform.VariableReplacements repl,repl_1,repl_2;
      DAE.ComponentRef cr1;
      list<BackendDAE.Equation> eqns_1,seqns_1,eqns;
      list<Integer> varIndexList, elimVarIndexList_1;
      Integer elimVarIndex;
      BackendDAE.Equation e;
      DAE.Exp e1,e2;
      BackendDAE.Var cr1Var;
      DAE.ElementSource source "origin of equation";
      array<Option<BackendDAE.Var>> varOptArr;
      BackendDAE.Var elimVar;

    case ({},_,vars,knvars,mvars,repl,_,m,elimVarIndexList,false) then
      ({},{},mvars,repl); 
      
    case (e::eqns,eqnIndex,vars,knvars,mvars,repl,inDoubles,m,elimVarIndexList,false) equation
      //true = RTOpts.eliminationLevel() > 0;
      //false = equationHasZeroCrossing(e);
      {e} = BackendVarTransform.replaceEquations({e},repl);
      
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
      repl_1 = BackendVarTransform.addReplacement(repl, cr1, e2);
      //failCheck = checkCircularEquation(cr1,e2,e);
      mvars_1 = BaseHashTable.add((cr1,0),mvars);
      (eqns_1,seqns_1,mvars_2,repl_2) = eliminateVariablesDAE2(eqns, eqnIndex + 1, vars, knvars, mvars_1, repl_1, inDoubles, m, elimVarIndexList_1, failCheck);
    then
      (eqns_1,(BackendDAE.SOLVED_EQUATION(cr1,e2,source) :: seqns_1),mvars_2,repl_2);
      
    // Next equation.
    case ((e :: eqns),eqnIndex,vars,knvars,mvars,repl,inDoubles,m,elimVarIndexList,false)
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
  (exp,source) := matchcontinue(eqn,cr)
  local DAE.Exp e1,e2,fSol,fbExp;
    list<list<BackendDAE.Equation>> tbs;
    list<BackendDAE.Equation> fb;
    BackendDAE.Equation fbEqn;
    list<DAE.Exp> tbExps,tbSols,conds;
    Integer eindx,indx;
    DAE.ElementSource source "origin of equation";
    case(BackendDAE.EQUATION(e1,e2,source),cr) equation
      (exp,_) = ExpressionSolve.solve(e1,e2,DAE.CREF(cr,DAE.T_REAL_DEFAULT));      
    then (exp,source);
    case(eqn,cr) equation
      /*print("failed solving ");print(Exp.printComponentRefStr(cr));print(" from equation :");
      print(equationStr(eqn));print("\n");*/
    then fail();
  end matchcontinue;
end solveEqn2;

public function getSubSystemDaeForVars "Returns a subsystem dae given a list of equations and a list of 
variables as indices."
  input list<Integer> eqnIndxLst;
  input list<Integer> varIndxLst;
  input BackendDAE.BackendDAE dae;
  output BackendDAE.BackendDAE outDae;
algorithm
  outDae:= matchcontinue(eqnIndxLst,varIndxLst,dae)
  local 
    list<BackendDAE.Equation> eqnLst;
    list<BackendDAE.Var> varLst; 
    BackendDAE.EqSystem eqsys1;
    list<Integer> fixedIndex;
    case(eqnIndxLst,varIndxLst,dae) equation
      BackendDAE.DAE(eqs=(eqsys1::_)) = dae;
       fixedIndex = List.map1r(eqnIndxLst,intAdd,-1);
       eqnLst = List.map1r(fixedIndex,BackendDAEUtil.equationNth,BackendEquation.daeEqns(eqsys1)); //daeArrayEqns equationNth
       varLst = List.map1r(varIndxLst,BackendVariable.getVarAt,BackendVariable.daeVars(eqsys1));
      then setDaeVarsAndEqs(dae,BackendDAEUtil.listEquation(eqnLst),BackendDAEUtil.listVar(varLst));
    case(_,_,_) equation
     //print("getSubSystemDaeForVars failed\n");
    then fail();
  end matchcontinue;
end getSubSystemDaeForVars;
  
public function setDaeVars "
   note: this function destroys matching
"
  input BackendDAE.BackendDAE systIn;
  input BackendDAE.Variables newVarsIn;
  output BackendDAE.BackendDAE sysOut;
algorithm
  sysOut:= match(systIn,newVarsIn) 
    local
       BackendDAE.Variables orderedVars;
       BackendDAE.EquationArray orderedEqs;
       Option<BackendDAE.IncidenceMatrix> m;
       Option<BackendDAE.IncidenceMatrixT> mT;
       BackendDAE.Matching matching;
       BackendDAE.Shared shared;
       BackendDAE.EquationArray eqns;
       BackendDAE.Variables newVars;
       list<BackendDAE.EqSystem> eqlist;
      case (BackendDAE.DAE(BackendDAE.EQSYSTEM(_,eqns,m,mT,matching)::eqlist,shared),newVars)
        then 
           BackendDAE.DAE(BackendDAE.EQSYSTEM(newVars,eqns,m,mT,matching)::eqlist,shared);   
  end match;
end setDaeVars;    


public function setDaeKnownVars 
  input BackendDAE.BackendDAE dae;
  input BackendDAE.Variables newVarsIn;
  output BackendDAE.BackendDAE odae;
algorithm
  odae := matchcontinue(dae,newVarsIn)
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
    BackendDAE.AliasVariables aliasVars "mappings of alias-variables to real-variables"; // added asodja 2010-03-03
    BackendDAE.EquationArray initialEqs "initialEqs ; Initial equations" ;
    BackendDAE.EquationArray removedEqs "these are equations that cannot solve for a variable. for example assertions, external function calls, algorithm sections without effect" ;
    array<BackendDAE.MultiDimEquation> arrayEqs "arrayEqs ; Array equations" ;
    array<DAE.Algorithm> algorithms "algorithms ; Algorithms" ;
    BackendDAE.EventInfo eventInfo "eventInfo" ;
    BackendDAE.ExternalObjectClasses extObjClasses "classes of external objects, contains constructor & destructor";
    BackendDAE.BackendDAEType backendDAEType "indicate for what the BackendDAE is used"; 
    
    case(BackendDAE.DAE(systList,(shared as BackendDAE.SHARED(externalObjects=externalObjects,aliasVars=aliasVars,initialEqs=initialEqs,
                                   removedEqs=removedEqs,arrayEqs=arrayEqs,algorithms=algorithms,eventInfo=eventInfo,
                                   extObjClasses=extObjClasses,backendDAEType=backendDAEType))),knownVars) 
    equation
       shared = BackendDAE.SHARED(knownVars,externalObjects,aliasVars,initialEqs,removedEqs,arrayEqs,algorithms,eventInfo,extObjClasses,backendDAEType);                              
    then
       BackendDAE.DAE(systList,shared); 
       
  end matchcontinue;
end setDaeKnownVars;

public function setDaeVarsAndEqs "
   note: this function destroys matching
"
  input BackendDAE.BackendDAE systIn;
  input BackendDAE.EquationArray newEqnsIn;
  input BackendDAE.Variables newVarsIn;
  output BackendDAE.BackendDAE sysOut;
algorithm
  sysOut:= match(systIn,newEqnsIn,newVarsIn) 
    local
       BackendDAE.Variables orderedVars;
       BackendDAE.EquationArray orderedEqs;
       Option<BackendDAE.IncidenceMatrix> m;
       Option<BackendDAE.IncidenceMatrixT> mT;
       BackendDAE.Matching matching;
       BackendDAE.Shared shared;
       BackendDAE.EquationArray newEqns;
       BackendDAE.Variables newVars;
       list<BackendDAE.EqSystem> eqlist;
      case (BackendDAE.DAE(BackendDAE.EQSYSTEM(_,_,m,mT,matching)::eqlist,shared),newEqns,newVars)
        then 
           BackendDAE.DAE(BackendDAE.EQSYSTEM(newVars,newEqns,m,mT,matching)::eqlist,shared);   
  end match;
end setDaeVarsAndEqs;  
  
  public function extractEquationsForUC
"
  author: Daniel Hedberg, 2011-01
  modified by: Leonardo Laguna, 2012-01
"
  input BackendDAE.BackendDAE daelow;
  input BackendDAE.IncidenceMatrix m;
  input list<list<Integer>> blocks;
  output list<list<Integer>> out;
algorithm
  out := matchcontinue (daelow, m, blocks)
    local
      list<list<Integer>> blocks_1, blocks_2;
      list<Integer> refineVarIndexList, refineVarIndexList_1;
    case (daelow, m, blocks) equation
      refineVarIndexList = getUncertainRefineVariablesInBlocks(daelow, m, blocks);
      blocks_1 = removeSquareBlocksUC(m, blocks);
      blocks_2 = removeNonInfluencingBlocksUC(daelow, m, blocks_1, {});
      // Make sure that all variables with attribute uncertain set to
      // Uncertainty.refine are present in the remaining blocks.
      refineVarIndexList_1 = getUncertainRefineVariablesInBlocks(daelow, m, blocks_2);
      true = intEq(listLength(refineVarIndexList), listLength(refineVarIndexList_1));
    then
      blocks_2;
    // Raise an error if not all variables with attribute uncertain set to
    // Uncertainty.refine are present in the remaining blocks.
    case (daelow, m, blocks) equation
      refineVarIndexList = getUncertainRefineVariablesInBlocks(daelow, m, blocks);
      blocks_1 = removeSquareBlocksUC(m, blocks);
      blocks_2 = removeNonInfluencingBlocksUC(daelow, m, blocks_1, {});
      refineVarIndexList_1 = getUncertainRefineVariablesInBlocks(daelow, m, blocks_2);
      false = intEq(listLength(refineVarIndexList), listLength(refineVarIndexList_1));
      print("extractEquationsForUC: Not all variables with attribute uncertain = Uncertainty.refine are present in the remaining blocks!\n");
    then
      fail();
    case (_,_,_) equation print("extractEquationsForUC failed!\n"); then fail();
  end matchcontinue;
end extractEquationsForUC;
  
  
  protected function removeNonInfluencingBlocksUC
"
  author: Daniel Hedberg, 2011-01
  modified by: Leonardo Laguna, 2012-01
"
  input BackendDAE.BackendDAE daelow;
  input BackendDAE.IncidenceMatrix m;
  input list<list<Integer>> blocks;
  input list<Integer> uncertainRefineVarsInPreviousBlocks;
  output list<list<Integer>> out;
algorithm
  out := matchcontinue (daelow, m, blocks, uncertainRefineVarsInPreviousBlocks)
    local
      list<Integer> block_, uncertainRefineVarsInBlock, uncertainRefineVars;
      list<list<Integer>> blocksRest, blocks_1;
    case (_, _, {}, _) then {};
    // New vars with uncertain = refine in this block? - Yes, keep block.
     case (daelow, m, block_ :: blocksRest, uncertainRefineVarsInPreviousBlocks) equation
      uncertainRefineVarsInBlock = getUncertainRefineVariablesInBlock(daelow, m, block_);
      uncertainRefineVars = List.union(uncertainRefineVarsInBlock, uncertainRefineVarsInPreviousBlocks);
      false = intEq(listLength(uncertainRefineVars), listLength(uncertainRefineVarsInPreviousBlocks)); // New refine vars
      blocks_1 = removeNonInfluencingBlocksUC(daelow, m, blocksRest, uncertainRefineVars);
    then
      block_ :: blocks_1;
    // New vars with uncertain = refine in this block? - No, discard block.
    case (daelow, m, block_ :: blocksRest, uncertainRefineVarsInPreviousBlocks) equation
      uncertainRefineVarsInBlock = getUncertainRefineVariablesInBlock(daelow, m, block_);
      uncertainRefineVars = List.union(uncertainRefineVarsInBlock, uncertainRefineVarsInPreviousBlocks);
      true = intEq(listLength(uncertainRefineVars), listLength(uncertainRefineVarsInPreviousBlocks)); // No new refine vars
      blocks_1 = removeNonInfluencingBlocksUC(daelow, m, blocksRest, uncertainRefineVars);
    then
      blocks_1;
    case (_,_,_,_) equation print("removeNonInfluencingBlocksUC failed!\n"); then fail();
  end matchcontinue;
end removeNonInfluencingBlocksUC;
  
  protected function removeSquareBlocksUC
"
  author: Daniel Hedberg, 2011-01
  modified by: Leonardo Laguna, 2012-01
"
  input BackendDAE.IncidenceMatrix m;
  input list<list<Integer>> blocks;
  output list<list<Integer>> out;
algorithm
  out := matchcontinue (m, blocks)
    local
      list<Integer> block_, block_1, vars;
      list<list<Integer>> blocksRest, blocks_1;
    case (_, {}) then {};
    case (m, block_ :: blocksRest) equation
      vars = getVariablesInBlock(m, block_);
      true = intEq(listLength(vars), listLength(block_)); // Square? - Remove block
      blocks_1 = removeSquareBlocksUC(m, blocksRest);
    then
      blocks_1;
    case (m, block_ :: blocksRest) equation
      blocks_1 = removeSquareBlocksUC(m, blocksRest);
    then
      block_ :: blocks_1;
    case (_,_) equation print("removeSquareBlocksUC failed!\n"); then fail();
  end matchcontinue;
end removeSquareBlocksUC;
  
  public function getVariablesInBlocks
"
  author: Daniel Hedberg, 2011-01
  modified by: Leonardo Laguna, 2012-01

  Returns lists with the indexes of all variables present in the given list of blocks.
"
  input BackendDAE.IncidenceMatrix m;
  input list<list<Integer>> blocks;
  output list<Integer> varIndexList;
algorithm
  varIndexList := matchcontinue (m, blocks)
    local
      list<Integer> block_, vars, vars_1, vars_2;
      list<list<Integer>> blocksRest;
    case (_, {}) then {};
    case (m, block_ :: blocksRest) equation
      vars = getVariablesInBlock(m, block_);
      vars_1 = getVariablesInBlocks(m, blocksRest);
      vars_2 = List.union(vars, vars_1);
    then
      vars_2;
    case (_,_) equation print("getVariablesInBlocks failed!\n"); then fail();
  end matchcontinue;
end getVariablesInBlocks;
  
  protected function getVariablesInBlock
"
  author: Daniel Hedberg, 2011-01
  modified by: Leonardo Laguna, 2012-01

  Returns a list with the indexes of the variables in the specified block of
  equations (eqns).
"
  input BackendDAE.IncidenceMatrix m;
  input list<Integer> eqns;
  output list<Integer> vars;
algorithm 
  vars := matchcontinue (m, eqns)
    local
      Integer eqn;
      list<Integer> eqnsRest, vars, vars_1, vars_2;
    case (_, {}) then {};
    case (m, eqn :: eqnsRest) equation
      vars = m[eqn]; // Variable indexes in equation
      vars_1 = getVariablesInBlock(m, eqnsRest);
      vars_2 = List.union(vars, vars_1); 
    then
      vars_2;
    case (_,_) equation print("getVariablesInBlock failed!\n"); then fail();
  end matchcontinue;
end getVariablesInBlock;
  
  
  public function getUncertainRefineVariablesInBlocks
"
  author: Daniel Hedberg, 2011-01
	modified by: Leonardo Laguna, 2012-01
"
  input BackendDAE.BackendDAE daelow;
  input BackendDAE.IncidenceMatrix m;
  input list<list<Integer>> blocks;
  output list<Integer> varIndexList;
algorithm
  varIndexList := matchcontinue (daelow, m, blocks)
    local
      list<Integer> block_, vars, vars_1, vars_2;
      list<list<Integer>> blocksRest;
    case (_, _, {}) then {};
    case (daelow, m, block_ :: blocksRest) equation
      vars = getUncertainRefineVariablesInBlock(daelow, m, block_);
      vars_1 = getUncertainRefineVariablesInBlocks(daelow, m, blocksRest);
      vars_2 = List.union(vars, vars_1);
    then
      vars_2;
    case (_,_,_) equation print("getUncertainRefineVariablesInBlocks failed!\n"); then fail();
  end matchcontinue;
end getUncertainRefineVariablesInBlocks;
  
protected function getUncertainRefineVariablesInBlock
"
  author: Daniel Hedberg, 2011-01
  modified by: Leonardo Laguna, 2012-01

  Returns a list with the indexes of all variables in the specified block of
  equations (eqns) that have the uncertain attribute set to Uncertainty.Refine.
"
  input BackendDAE.BackendDAE daelow;
  input BackendDAE.IncidenceMatrix m;
  input list<Integer> eqns;
  output list<Integer> vars;
algorithm 
  vars := matchcontinue (daelow, m, eqns)
    local
      Integer eqn;
      list<Integer> eqnsRest, vars, vars_1, vars_2;
    case (_, _, {}) then {};
    case (daelow, m, eqn :: eqnsRest) equation
      vars = getUncertainRefineVariablesInEquation(daelow, m, eqn);
      vars_1 = getUncertainRefineVariablesInBlock(daelow, m, eqnsRest);
      vars_2 = List.union(vars, vars_1);
    then
      vars_2;
    case (_,_,_) equation print("getUncertainRefineVariablesInBlock failed!\n"); then fail();
  end matchcontinue;
end getUncertainRefineVariablesInBlock;
  
  protected function getUncertainRefineVariablesInEquation
"
  author: Daniel Hedberg, 2011-01
  modified by: Leonardo Laguna, 2012-01

  Returns a list with the indexes of all variables in the equation, with the
  specified index, that have the uncertain attribute set to Uncertainty.Refine.
"
  input BackendDAE.BackendDAE daelow;
  input BackendDAE.IncidenceMatrix m;
  input Integer eqn;
  output list<Integer> out;
algorithm 
  out := matchcontinue (daelow, m, eqn)
    local
      list<Integer> vars, vars_1;
      BackendDAE.Variables allVars;
    case (BackendDAE.DAE(eqs = (BackendDAE.EQSYSTEM(orderedVars = allVars))::_), m, eqn) equation // Note: check the noet on the type EqSystems if something fails
      vars = m[eqn];
      vars_1 = getUncertainRefineVariableIndexes(allVars, vars);
    then
      vars_1;
    case (_,_,_) equation print("getUncertainRefineVariablesInEquation failed!\n"); then fail();
  end matchcontinue;
end getUncertainRefineVariablesInEquation;
  
  public function getUncertainRefineVariableIndexes
"
  author: Daniel Hedberg, 2011-01
  modified by: Leonardo Laguna, 2012-01
  
  Returns a list with the indexes of all variables in variableIndexList which
  have the uncertain attribute set to Uncertainty.Refine.
"
  input BackendDAE.Variables allVariables;
  input list<Integer> variableIndexList;
  output list<Integer> out;
algorithm 
  out := matchcontinue (allVariables, variableIndexList)
    local
      list<Integer> variableIndexListRest, refineVariableIndexList;
      Integer index;
      BackendDAE.Var var;
    case (_, {}) then
      {};
    // Variable has its uncertain attribute set to Uncertainty.Refine?
    case (allVariables, index :: variableIndexListRest) equation
      var = BackendVariable.getVarAt(allVariables, index);
      true = BackendVariable.varHasUncertainValueRefine(var);
      refineVariableIndexList = getUncertainRefineVariableIndexes(allVariables, variableIndexListRest);
    then
      index :: refineVariableIndexList;
    // Variable is missing the uncertain attribute or it is not set to Uncertainty.Refine?
    case (allVariables, index :: variableIndexListRest) equation
      var = BackendVariable.getVarAt(allVariables, index);
      false = BackendVariable.varHasUncertainValueRefine(var);
      refineVariableIndexList = getUncertainRefineVariableIndexes(allVariables, variableIndexListRest);
    then
      refineVariableIndexList;
    case (_,_) equation print("getUncertainRefineVariableIndexes failed!\n"); then fail();
  end matchcontinue;
end getUncertainRefineVariableIndexes;
  
  

 
  
public function getEquationsInBlocks
"
  author: Daniel Hedberg, 2011-01
	modified by: Leonardo Laguna, 2012-01

  Returns lists with the indexes of all equations present in the given list of blocks.
"
  input list<list<Integer>> blocks;
  output list<Integer> eqnIndexList;
algorithm
  eqnIndexList := matchcontinue (blocks)
    local
      list<Integer> eqns, eqns_1, eqns_2;
      list<list<Integer>> blocksRest;
    case ({}) then {};
    case (eqns :: blocksRest) equation
      eqns_1 = getEquationsInBlocks(blocksRest);
      eqns_2 = List.union(eqns, eqns_1);
    then
      eqns_2;
    case (_) equation print("getEquationsInBlocks failed!\n"); then fail();
  end matchcontinue;
end getEquationsInBlocks;  



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
    local list<DAE.ComponentRef> crefs;
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
      list<DAE.Var> varLst,varLst2;
    case(ht,recordCr,{}) then ht;
    // found array
    case(ht,recordCr,DAE.TYPES_VAR(name=name,ty=tp)::varLst) equation
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
    case(ht,recordCr,_::varLst) equation      
      ht = findArraysInRecordLst(ht,recordCr,varLst);
    then ht;
      
  end matchcontinue;
end findArraysInRecordLst;   


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
        list<DAE.ComponentRef> crefs,cindex;
        DAE.ComponentRef c1;
        list<DAE.Exp> expl1,expl2;
        list<DAE.ComponentRef> cindex2;
        HashTable.HashTable ht;
    case({},ht) then  ht;
    case( (eq1 as BackendDAE.ALGORITHM(in_=expl1,out=expl2)) :: eqs,ht)
      equation
        ht = findArraysPartiallyIndexed2(expl1,ht,HashTable.emptyHashTable());
        ht = findArraysPartiallyIndexed2(expl2,ht,HashTable.emptyHashTable());
        ht = findArraysPartiallyIndexed1(eqs,ht);
      then
        ht;
       
    case((eq1 as BackendDAE.ARRAY_EQUATION(crefOrDerCref = expl1)) :: eqs,ht)
      equation
        ht = findArraysPartiallyIndexed2(expl1,ht,HashTable.emptyHashTable());
        ht = findArrayVariables(expl1,ht) "finds all array variables, including earlier special case for v = foo(..)";        
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

protected function findArraysPartiallyIndexed2 "
"
  input list<DAE.Exp> inRef "The list of expressions to traverse/search for crefs";
  input HashTable.HashTable indubRef "ComponentReferences that are duplicate(y[1,1],y[1,2] is a double)";
  input HashTable.HashTable inht "Added componentReferences";
  output HashTable.HashTable outHt;
  
algorithm
  outHt := matchcontinue(inRef,indubRef,inht)
    local
      DAE.ComponentRef c1,c2,c3;
      list<DAE.ComponentRef> crefs1,crefs2,crefs3;
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
        _ = BaseHashTable.get(c2,ht);// if we have one occurance, most likely it will be more.
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

  
end Uncertainties;  
  
