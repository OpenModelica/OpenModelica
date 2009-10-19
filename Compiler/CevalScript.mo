/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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

package CevalScript
" file:	 CevalScript.mo
  package:      CevalScript
  description: Constant propagation of expressions

  RCS: $Id: CevalScript.mo 3774 2008-12-15 07:56:54Z adrpo $

  This module handles scripting.
 
  Input: 
 	Env: Environment with bindings
 	Exp: Expression to evaluate
 	Bool flag determines whether the current instantiation is implicit
 	InteractiveSymbolTable is optional, and used in interactive mode,
 	e.g. from OMShell
 	
  Output:
 	Value: The evaluated value
      InteractiveSymbolTable: Modified symbol table
      Subscript list : Evaluates subscripts and generates constant expressions."

public import DAELow;
public import Exp;
public import Env;
public import Interactive;
public import Values;
public import Absyn;
public import Types;
public import Ceval;

protected import SimCodegen;
protected import AbsynDep;
protected import Refactor;
protected import DAEQuery;
protected import XMLDump;
protected import ClassLoader;
protected import Parser;
protected import Dump;
protected import ClassInf;
protected import Codegen;
protected import Settings;
protected import SCode;
protected import DAE;
protected import Util;
protected import ModUtil;
protected import RTOpts;
protected import Debug;
protected import Lookup;
protected import Inst;
protected import InstanceHierarchy;
protected import Prefix;
protected import Connect;
protected import Print;
protected import System;
protected import Error;
protected import Static;
protected import ConnectionGraph;
protected import UnitAbsyn;
protected import UnitParserExt;
protected import UnitAbsynBuilder;

public function cevalInteractiveFunctions 
"function cevalInteractiveFunctions
  This function evaluates the functions 
  defined in the interactive environment."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.Exp inExp "expression to evaluate";
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outCache,outValue,outInteractiveSymbolTable):=
  matchcontinue (inCache,inEnv,inExp,inInteractiveSymbolTable,inMsg)
    local
      Absyn.Path path,p1,classpath;
      list<SCode.Class> p_1,sp,fp;
      list<Env.Frame> env;
      SCode.Class c;
      String s1,str,varid,res,cmd,executable,method_str,initfilename,cit,pd,executableSuffixedExe,sim_call,result_file,
      omhome,pwd,filename_1,filename,omhome_1,plotCmd,tmpPlotFile,call,str_1,scriptstr,res_1,mp,pathstr,name,cname;
      Exp.ComponentRef cr,fcr,cref,classname;
      Interactive.InteractiveSymbolTable st,newst,st_1,st_2;
      Absyn.Program p,pnew,newp,ptot;
      list<Interactive.InstantiatedClass> ic,ic_1;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      tuple<Types.TType, Option<Absyn.Path>> tp,simType;
      Absyn.Class class_;
      DAE.DAElist dae_1,dae;
      list<DAE.Element> dael;
      DAELow.DAELow daelow;
      DAELow.Variables vars;
      DAELow.EquationArray eqnarr;
      DAELow.MultiDimEquation[:] ae;
      list<Integer>[:] m,mt;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      Values.Value ret_val,simValue,size_value,value,v;      
      Exp.Exp filenameprefix,exp,starttime,stoptime,tolerance,interval,method,size_expression,
             funcref,bool_exp,storeInTemp,noClean,options, asInSimulationCode,addOriginalIncidenceMatrix,
             addSolvingInfo,addMathMLCode,dumpResiduals;
      Absyn.ComponentRef cr_1;
      Integer size,length,rest;
      list<String> vars_1,vars_2,args;
      Real t1,t2,time;
      Interactive.InteractiveStmts istmts;
      Boolean bval;
      Env.Cache cache;
      Absyn.Path className;
      list<Interactive.LoadedFile> lf;
      AbsynDep.Depends aDep;
    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "lookupClass"),expLst = {Exp.CREF(componentRef = cr)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        path = Static.componentRefToPath(cr);
        ptot = Interactive.getTotalProgram(path,p);
        p_1 = SCode.elaborate(ptot);
        (cache,env) = Inst.makeEnvFromProgram(cache,p_1, Absyn.IDENT(""));
        (cache,c,env) = Lookup.lookupClass(cache,env, path, true);
        SOME(p1) = Env.getEnvPath(env);
        s1 = ModUtil.pathString(p1);
        Print.printBuf("Found class ");
        Print.printBuf(s1);
        Print.printBuf("\n\n");
        str = Print.getString();
      then
        (cache,Values.STRING(str),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "typeOf"),
        expLst = {Exp.CODE(Absyn.C_VARIABLENAME(Absyn.CREF_IDENT(name = varid)),_)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        tp = Interactive.getTypeOfVariable(varid, iv);
        str = Types.unparseType(tp);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "clear"),expLst = {}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg) 
    then (cache,Values.BOOL(true),Interactive.emptySymboltable); 

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "clearVariables"),expLst = {}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        depends = aDep,
        explodedAst = fp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf,
        loadedFiles = lf)),msg)
      equation 
        newst = Interactive.SYMBOLTABLE(p,aDep,fp,ic,{},cf,lf);
      then
        (cache,Values.BOOL(true),newst);

		// Note: This is not the environment caches, passed here as cache, but instead the cached instantiated classes.
    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "clearCache"),expLst = {}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,depends=aDep,explodedAst = fp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      equation 
        newst = Interactive.SYMBOLTABLE(p,aDep,fp,{},iv,cf,lf);
      then
        (cache,Values.BOOL(true),newst);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "list"),expLst = {}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str = Dump.unparseStr(p,false);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "list"),expLst = {Exp.CODE(Absyn.C_TYPENAME(path),_)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        class_ = Interactive.getPathedClassInProgram(path, p);
        str = Dump.unparseStr(Absyn.PROGRAM({class_},Absyn.TOP(),Absyn.TIMESTAMP(0.0,0.0)),false) ;
      then
        (cache,Values.STRING(str),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "jacobian"),
        expLst = {Exp.CREF(componentRef = cr)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,depends=aDep,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
        /*local DAELow.IfEquation[:] ifeqns;*/
      equation 
        path = Static.componentRefToPath(cr);
        ptot = Interactive.getTotalProgram(path,p);        
        p_1 = SCode.elaborate(ptot);
        (cache,env,_, dae as DAE.DAE(dael)) = 
        Inst.instantiateClass(cache,InstanceHierarchy.emptyInstanceHierarchy,p_1, path);
        ((dae as DAE.DAE(dael))) = DAE.transformIfEqToExpr(dae);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(path,dael,env));
        /*((daelow as DAELow.DAELOW(orderedVars=vars,orderedEqs=eqnarr,complexEqns = DAELow.COMPLEX_EQUATIONS(arrayEqs=ae,ifEqns=ifeqns)))) = DAELow.lower(dae, false, true) "no dummy state" ;*/
        ((daelow as DAELow.DAELOW(vars,_,_,eqnarr,_,_,ae,_,_,_))) = DAELow.lower(dae, false, true) "no dummy state" ;
        m = DAELow.incidenceMatrix(daelow);
        mt = DAELow.transposeMatrix(m);
        /* jac = DAELow.calculateJacobian(vars, eqnarr, ae,ifeqns, m, mt,false); */
        jac = DAELow.calculateJacobian(vars, eqnarr, ae, m, mt,false);
        res = DAELow.dumpJacobianStr(jac);
      then
        (cache,Values.STRING(res),Interactive.SYMBOLTABLE(p,aDep,sp,ic_1,iv,cf,lf));

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "translateModel"),
        expLst = {Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER()),filenameprefix}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        (cache,ret_val,st_1,_,_,_) = translateModel(cache,env, className, st, msg, filenameprefix,true);
      then
        (cache,ret_val,st_1);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "exportDAEtoMatlab"),
        expLst = {Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER()),filenameprefix}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        (cache,ret_val,st_1,_) = getIncidenceMatrix(cache,env, className, st, msg, filenameprefix);
      then
        (cache,ret_val,st_1);
        
      case (cache,env,
        Exp.CALL(
          path = Absyn.IDENT(name = "checkModel"),
          expLst = {Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER())}),
        (st as Interactive.SYMBOLTABLE(
          ast = p, 
          explodedAst = sp, 
          instClsLst = ic, 
          lstVarVal = iv, 
          compiledFunctions = cf)),msg)
           equation 
        (cache,ret_val,st_1) = checkModel(cache,env, className, st, msg);
      then
        (cache,ret_val,st_1);
        
         case (cache,env,
        Exp.CALL(
          path = Absyn.IDENT(name = "checkAllModelsRecursive"),
          expLst = {Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER())}),
        (st as Interactive.SYMBOLTABLE(
          ast = p,
          explodedAst = sp,
          instClsLst = ic,
          lstVarVal = iv,
          compiledFunctions = cf)),msg)
        equation
          (cache,ret_val,st_1) = checkAllModelsRecursive(cache, env, className, st, msg);
        then
          (cache,ret_val,st_1);

      case (cache,env,
        Exp.CALL(
          path = Absyn.IDENT(name = "translateGraphics"),
          expLst = {Exp.CODE(Absyn.C_TYPENAME(className),Exp.OTHER())}),
        (st as Interactive.SYMBOLTABLE(
          ast = p,
          explodedAst = sp,
          instClsLst = ic,
          lstVarVal = iv,
          compiledFunctions = cf)),msg)
           equation 
        (cache,ret_val,st_1) = translateGraphics(cache,env, className, st, msg);
      then
        (cache,ret_val,st_1);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "setCompileCommand"),
        expLst = {Exp.SCONST(string = cmd)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg) /* (Values.STRING(\"The model have been translated\"),st\') */ 
      equation 
        cmd = Util.rawStringToInputString(cmd);
        Settings.setCompileCommand(cmd);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "setPlotCommand"),
        expLst = {Exp.SCONST(string = cmd)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        cmd = Util.rawStringToInputString(cmd);
        Settings.setPlotCommand(cmd);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "getSettings"),expLst = {}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      local String str1,res;
      equation 
        res = "";
        str1 = Settings.getCompileCommand();
        res = Util.stringAppendList({res,"Compile command: ", str1,"\n"});
        str1 = Settings.getTempDirectoryPath();
        res = Util.stringAppendList({res,"Temp folder path: ", str1,"\n"});
        str1 = Settings.getInstallationDirectoryPath();
        res = Util.stringAppendList({res,"Installation folder: ", str1,"\n"});
        str1 = Settings.getPlotCommand();
        res = Util.stringAppendList({res,"Plot command: ", str1,"\n"});
        str1 = Settings.getModelicaPath();
        res = Util.stringAppendList({res,"Modelica path: ", str1,"\n"});
      then
        (cache,Values.STRING(res),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "setTempDirectoryPath"),expLst = {Exp.SCONST(string = cmd)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        cmd = Util.rawStringToInputString(cmd);
        Settings.setTempDirectoryPath(cmd);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "setInstallationDirectoryPath"),
        expLst = {Exp.SCONST(string = cmd)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        cmd = Util.rawStringToInputString(cmd);
        Settings.setInstallationDirectoryPath(cmd);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "getTempDirectoryPath"),expLst = {}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      local String res;
      equation 
        res = Settings.getTempDirectoryPath();
      then
        (cache,Values.STRING(res),st);
        
    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "getInstallationDirectoryPath"),expLst = {}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      local String res;
      equation 
        res = Settings.getInstallationDirectoryPath();
      then
        (cache,Values.STRING(res),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "setModelicaPath"),expLst = {Exp.SCONST(string = cmd)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      equation 
        cmd = Util.rawStringToInputString(cmd);
        Settings.setModelicaPath(cmd);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,(exp as 
      Exp.CALL( 
        path = Absyn.IDENT(name = "buildModel"), 
        expLst = 
        {Exp.CODE(Absyn.C_TYPENAME(className),_), 
         starttime,
         stoptime, 
         interval, 
         tolerance, 
         method,
         filenameprefix, 
         storeInTemp,
         noClean,
         options})),
         (st_1 as Interactive.SYMBOLTABLE( 
           ast = p, 
           explodedAst = sp, 
           instClsLst = ic, 
           lstVarVal = iv, 
           compiledFunctions = cf)),msg)
      equation 
        (cache,executable,method_str,st,initfilename) = buildModel(cache,env, exp, st_1, msg);
      then
        (cache,Values.ARRAY({Values.STRING(executable),Values.STRING(initfilename)}),st);
        
    case (cache,env,(exp as 
      Exp.CALL(
        path = Absyn.IDENT(name = "buildModel"),
        expLst = 
        {
        Exp.CODE(Absyn.C_TYPENAME(className),_),
        starttime, 
        stoptime,
        interval,
        tolerance,
        method,
        filenameprefix,
        storeInTemp,
        noClean,options})),
      (st_1 as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg) /* failing build_model */  
    then (cache,Values.ARRAY({Values.STRING(""),Values.STRING("")}),st_1); 

    case (cache,env,(exp as 
      Exp.CALL( path = Absyn.IDENT(name = "buildModelBeast"), expLst = {Exp.CODE(Absyn.C_TYPENAME(className),_), starttime,
         stoptime, interval, tolerance, method, filenameprefix, storeInTemp,noClean,options})),
         (st_1 as Interactive.SYMBOLTABLE( ast = p, explodedAst = sp, instClsLst = ic, lstVarVal = iv, compiledFunctions = cf)),msg)
      equation 
        (cache,executable,method_str,st,initfilename) = buildModelBeast(cache,env, exp, st_1, msg);
      then
        (cache,Values.ARRAY({Values.STRING(executable),Values.STRING(initfilename)}),st);

    /* adrpo: see if the model exists before simulation! */
    case (cache,env,(exp as
      Exp.CALL(path = Absyn.IDENT(name = "simulate"),
        expLst = {Exp.CODE(Absyn.C_TYPENAME(className),_),starttime,stoptime,interval,tolerance,method,filenameprefix,
        storeInTemp,noClean,options})),
      (st_1 as Interactive.SYMBOLTABLE(
        ast = p, explodedAst = sp, instClsLst = ic, lstVarVal = iv, compiledFunctions = cf)),msg)
      local
        Absyn.ComponentRef crefCName;
        String errMsg;
      equation
        crefCName = Absyn.pathToCref(className);
        false = Interactive.existClass(crefCName, p);
        errMsg = "Simulation Failed. Model: " +& Absyn.pathString(className) +& " does not exists! Please load it first before simulation.";
        simValue = Values.RECORD(Absyn.IDENT("SimulationResult"),
                                 {Values.STRING(errMsg)},
                                 {"resultFile"},-1);
      then
        (cache,simValue,st_1);

    case (cache,env,(exp as 
      Exp.CALL(
        path = Absyn.IDENT(name = "simulate"),
        expLst = 
        {
        Exp.CODE(Absyn.C_TYPENAME(className),_),
        starttime,
        stoptime,
        interval,
        tolerance,
        method,
        filenameprefix,
        storeInTemp,
        noClean,options})),
      (st_1 as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
        local String s1; Absyn.ComponentRef cr_name;
      equation         
        (cache,executable,method_str,st,_) = buildModel(cache,env, exp, st_1, msg) "Build and simulate model" ;
        cit = winCitation();
        pwd = System.pwd();
        pd = System.pathDelimiter();
        executableSuffixedExe = stringAppend(executable, System.getExeExt());
        sim_call = Util.stringAppendList({cit,pwd,pd,executableSuffixedExe,cit," > output.log 2>&1"});
        /* MathCore Version
        executableSuffixedExe = Util.linuxDotSlash() +& executable +& ".exe";        
        cr_name = Absyn.pathToCref(className);
        s1 = Absyn.componentRefStr(cr_name);
        
        sim_call = Util.stringAppendList({cit,executableSuffixedExe,cit," > output_" , s1 , ".log 2>&1"});
        */
        0 = System.systemCall(sim_call);
        result_file = Util.stringAppendList({executable,"_res.plt"});
        simValue = Values.RECORD(Absyn.IDENT("SimulationResult"),
                                 {Values.STRING(result_file)},
                                 {"resultFile"},-1);
        simType = (Types.T_COMPLEX(ClassInf.RECORD("SimulationResult"),
                                   {Types.VAR("resultFile",
                                    Types.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
                                    false,(Types.T_STRING({}),NONE),
                                    Types.UNBOUND())},
                                    NONE,NONE),NONE);
        newst = Interactive.addVarToSymboltable("currentSimulationResult", simValue, simType, st);
      then
        (cache,simValue,newst);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "simulate"),
        expLst = 
        {
        Exp.CODE(Absyn.C_TYPENAME(className),_),
        starttime,
        stoptime,
        interval,
        tolerance,
        method,
        filenameprefix,
        storeInTemp,
        noClean,options}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
      local String errorStr;
      equation 
        omhome = Settings.getInstallationDirectoryPath() "simulation fail for some other reason than OPENMODELICAHOME not being set." ;
        errorStr = Error.printMessagesStr();
        res = Util.stringAppendList({"Simulation failed.\n",errorStr});
        simValue = Values.RECORD(Absyn.IDENT("SimulationResult"),
                                 {Values.STRING(res)},
                                 {"resultFile"},-1);
      then
        (cache,simValue,st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "simulate"),
      expLst = {Exp.CODE(Absyn.C_TYPENAME(className),_),starttime,stoptime,interval,tolerance,method,filenameprefix,noClean,options}),
      (st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        simValue = Values.RECORD(Absyn.IDENT("SimulationResult"),
                   {Values.STRING("Simulation Failed. Environment variable OPENMODELICAHOME not set.")},
                   {"resultFile"},-1);
      then
        (cache,simValue,st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "instantiateModel"),
        expLst = {Exp.CODE(Absyn.C_TYPENAME(className),_)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,depends=aDep,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local Absyn.Path className;
        Absyn.ComponentRef crefCName;
      equation 
        crefCName = Absyn.pathToCref(className);
        true = Interactive.existClass(crefCName, p);
        ptot = Interactive.getTotalProgram(className,p);
        p_1 = SCode.elaborate(ptot);
        (cache,env,_,(dae as DAE.DAE(dael))) = 
        Inst.instantiateClass(cache,InstanceHierarchy.emptyInstanceHierarchy,p_1,className);
        // ((dae as DAE.DAE(dael))) = DAE.transformIfEqToExpr(dael);        
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dael,env));
        str = DAE.dumpStr(dae);
      then
        (cache,Values.STRING(str),Interactive.SYMBOLTABLE(p,aDep,sp,ic_1,iv,cf,lf));

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "instantiateModel"),
        expLst = {Exp.CODE(Absyn.C_TYPENAME(className),_)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,depends=aDep,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg) /* model does not exist */ 
      equation 
				cr_1 = Absyn.pathToCref(className);
        false = Interactive.existClass(cr_1, p);
      then
        (cache,Values.STRING("Unknown model.\n"),Interactive.SYMBOLTABLE(p,aDep,sp,ic,iv,cf,lf));

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "instantiateModel"),
        expLst = {Exp.CODE(Absyn.C_TYPENAME(path),_)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,depends=aDep,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      equation 
        ptot = Interactive.getTotalProgram(path,p);
        p_1 = SCode.elaborate(ptot);
        str = Print.getErrorString() "we do not want error msg twice.." ;
        failure((_,_,_,_) = 
        Inst.instantiateClass(cache,InstanceHierarchy.emptyInstanceHierarchy,p_1,path));
        Print.clearErrorBuf();
        Print.printErrorBuf(str);
        str = Print.getErrorString();
      then
        (cache,Values.STRING(str),Interactive.SYMBOLTABLE(p,aDep,sp,ic,iv,cf,lf));

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "readSimulationResult"),
        expLst = {Exp.SCONST(string = filename),Exp.ARRAY(array = vars),size_expression}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg) /* function Ceval.ceval : (Env.Env, Exp.Exp, bool (implicit) ,
		    Interactive.InteractiveSymbolTable option, 
		    int option, ( dimensions )
		    Ceval.Msg)
	  => (Values.Value, Interactive.InteractiveSymbolTable option)
 */ 
      local list<Exp.Exp> vars;
      equation 
        (cache,(size_value as Values.INTEGER(size)),SOME(st)) = Ceval.ceval(cache,env, size_expression, true, SOME(st), NONE, msg);
				vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr);
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename_1 = Util.stringAppendList({pwd,pd,filename});
        value = System.readPtolemyplotDataset(filename_1, vars_1, size);
      then
        (cache,value,st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "readSimulationResult"),
        expLst = {Exp.SCONST(string = filename),Exp.ARRAY(ty = _),_}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      equation 
        Error.addMessage(Error.SCRIPT_READ_SIM_RES_ERROR, {});
      then
        fail();

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "readSimulationResultSize"),
        expLst = {Exp.SCONST(string = filename)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      equation 
        pwd = System.pwd();
        pd = System.pathDelimiter();
        filename_1 = Util.stringAppendList({pwd,pd,filename});
        value = System.readPtolemyplotDatasetSize(filename_1);
      then
        (cache,value,st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "readSimulationResultSize"),
        expLst = {Exp.SCONST(string = filename)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      equation 
        Error.addMessage(Error.SCRIPT_READ_SIM_RES_SIZE_ERROR, {});
      then
        fail();

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "plot2"),
        expLst = {Exp.ARRAY(array = vars)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        list<Exp.Exp> vars;
        String uniqueStr;
      equation 
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "plot2" ;
        vars_2 = Util.listUnionElt("time", vars_1);
        
    
        (cache,Values.RECORD(orderd={Values.STRING(filename)}),_) = Ceval.ceval(cache,env, 
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, msg);
        value = System.readPtolemyplotDataset(filename, vars_2, 0);
        pwd = System.pwd();
        cit = winCitation();

        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.trim(omhome, "\"");
        pd = System.pathDelimiter();
        plotCmd = Util.stringAppendList({cit,omhome_1,pd,"bin",pd,"doPlot",cit});
        uniqueStr = intString(tick());
        tmpPlotFile = Util.stringAppendList({pwd,pd,"tmpPlot_",uniqueStr,".plt"});
        res = Values.writePtolemyplotDataset(tmpPlotFile, value, vars_2, "Plot by OpenModelica");
        call = Util.stringAppendList({cit,plotCmd," \"",tmpPlotFile,"\"",cit});

        _ = System.systemCall(call);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "plot2"),
        expLst = {Exp.ARRAY(array = vars)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      equation 
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        vars_2 = Util.listUnionElt("time", vars_1);
        (cache,Values.RECORD(orderd={Values.STRING(filename)}),_) = Ceval.ceval(cache,env, 
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, msg);
        failure(_ = System.readPtolemyplotDataset(filename, vars_2, 0));
      then
        (cache,Values.STRING("Error reading the simulation result."),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "plot2"),
        expLst = {Exp.ARRAY(array = vars)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      equation 
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        vars_2 = Util.listUnionElt("time", vars_1);
        failure((_,_,_) = Ceval.ceval(cache,env, 
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, Ceval.NO_MSG()));
      then
        (cache,Values.STRING("No simulation result to plot."),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "plot2"),
        expLst = {Exp.ARRAY(array = vars)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      then
        (cache,Values.STRING("Unknown error while plotting"),st);
   
//plotAll(model) - file missing
    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "plotAll"),
        expLst = {
        Exp.CODE(Absyn.C_TYPENAME(className),_),
  			Exp.SCONST(string = interpolation), Exp.SCONST(string = title), Exp.BCONST(bool = legend), Exp.BCONST(bool = grid), Exp.BCONST(bool = logX), Exp.BCONST(bool = logY), Exp.SCONST(string = xLabel), Exp.SCONST(string = yLabel), Exp.BCONST(bool = points), xRange, yRange
        }),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        Exp.Exp xRange, yRange;
        list<Exp.Exp> vars;
 //       list<String> vars_3;
        String interpolation, title, xLabel, yLabel, str, filename2;
        Boolean legend, grid, logX, logY, points;
      equation

//        vars = Util.listMap(vars,Exp.CodeVarToCref);
//        vars_1 = Util.listMap(vars, Exp.printExpStr) "plotAll" ;
//        vars_2 = Util.listUnionElt("time", vars_1);

				filename = Absyn.pathString(className);
				filename2 = Util.stringAppendList({filename, "_res.plt"});

        failure(_ = System.getVariableNames(filename2));
//        vars_2 = Util.stringSplitAtChar(str, " ");
//        vars_2 =


       // value = System.readPtolemyplotDataset(filename2, vars_2, 0);


 //       failure(_ = System.readPtolemyplotDataset(filename2, vars_2, 0));

      then
					(cache,Values.STRING("Error reading the simulation result."),st);
//        res = Values.sendPtolemyplotDataset(value, vars_2, "Plot by OpenModelica", interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, Exp.printExpStr(xRange), Exp.printExpStr(yRange));

//      then
 //       (cache,Values.BOOL(true),st);

//plotAll(model)
    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "plotAll"),
        expLst = {
        Exp.CODE(Absyn.C_TYPENAME(className),_),
  			Exp.SCONST(string = interpolation), Exp.SCONST(string = title), Exp.BCONST(bool = legend), Exp.BCONST(bool = grid), Exp.BCONST(bool = logX), Exp.BCONST(bool = logY), Exp.SCONST(string = xLabel), Exp.SCONST(string = yLabel), Exp.BCONST(bool = points), xRange, yRange
        }),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        Exp.Exp xRange, yRange;
        list<Exp.Exp> vars;
 //       list<String> vars_3;
        String interpolation, title, xLabel, yLabel, str, filename2;
        Boolean legend, grid, logX, logY, points;
      equation

//        vars = Util.listMap(vars,Exp.CodeVarToCref);
//        vars_1 = Util.listMap(vars, Exp.printExpStr) "plotAll" ;
//        vars_2 = Util.listUnionElt("time", vars_1);

				filename = Absyn.pathString(className);
				filename2 = Util.stringAppendList({filename, "_res.plt"});

        str = System.getVariableNames(filename2);
        vars_2 = Util.stringSplitAtChar(str, " ");
//        vars_2 =


        value = System.readPtolemyplotDataset(filename2, vars_2, 0);

        res = Values.sendPtolemyplotDataset(value, vars_2, "Plot by OpenModelica", interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, Exp.printExpStr(xRange), Exp.printExpStr(yRange));

      then
        (cache,Values.BOOL(true),st);

//plotAll() - missing file
    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "plotAll"),
        expLst = {
//        Exp.CODE(Absyn.C_TYPENAME(className),_),
  			Exp.SCONST(string = interpolation), Exp.SCONST(string = title), Exp.BCONST(bool = legend), Exp.BCONST(bool = grid), Exp.BCONST(bool = logX), Exp.BCONST(bool = logY), Exp.SCONST(string = xLabel), Exp.SCONST(string = yLabel), Exp.BCONST(bool = points), xRange, yRange
        }),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        Exp.Exp xRange, yRange;
        list<Exp.Exp> vars;
 //       list<String> vars_3;
        String interpolation, title, xLabel, yLabel, str;//, filename2;
        Boolean legend, grid, logX, logY, points;
      equation

         (cache,Values.RECORD(orderd={Values.STRING(filename)}),_) = Ceval.ceval(cache,env,
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, msg);
        failure(_ = System.getVariableNames(filename));
//        vars_2 = Util.stringSplitAtChar(str, " ");

//        failure(_ = System.readPtolemyplotDataset(filename, vars_2, 0));

      then
					(cache,Values.STRING("Error reading the simulation result."),st);

//plotAll()
    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "plotAll"),
        expLst = {
//        Exp.CODE(Absyn.C_TYPENAME(className),_),
  			Exp.SCONST(string = interpolation), Exp.SCONST(string = title), Exp.BCONST(bool = legend), Exp.BCONST(bool = grid), Exp.BCONST(bool = logX), Exp.BCONST(bool = logY), Exp.SCONST(string = xLabel), Exp.SCONST(string = yLabel), Exp.BCONST(bool = points), xRange, yRange
        }),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        Exp.Exp xRange, yRange;
        list<Exp.Exp> vars;
 //       list<String> vars_3;
        String interpolation, title, xLabel, yLabel, str;//, filename2;
        Boolean legend, grid, logX, logY, points;
      equation
        (cache,Values.RECORD(orderd={Values.STRING(filename)}),_) = Ceval.ceval(cache,env,
        Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, msg);
        str = System.getVariableNames(filename);
        vars_2 = Util.stringSplitAtChar(str, " ");
        value = System.readPtolemyplotDataset(filename, vars_2, 0);

        res = Values.sendPtolemyplotDataset(value, vars_2, "Plot by OpenModelica", interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, Exp.printExpStr(xRange), Exp.printExpStr(yRange));

      then
        (cache,Values.BOOL(true),st);



// plot(model, x)
    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "plot"),
        expLst = {
        Exp.CODE(Absyn.C_TYPENAME(className),_),
        Exp.ARRAY(array = vars),
  			Exp.SCONST(string = interpolation), Exp.SCONST(string = title), Exp.BCONST(bool = legend), Exp.BCONST(bool = grid), Exp.BCONST(bool = logX), Exp.BCONST(bool = logY), Exp.SCONST(string = xLabel), Exp.SCONST(string = yLabel), Exp.BCONST(bool = points), xRange, yRange
        }),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        Exp.Exp xRange, yRange;
        list<Exp.Exp> vars;
        String interpolation, title, xLabel, yLabel;
        Boolean legend, grid, logX, logY, points;
      equation

        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "plot" ;
        vars_2 = Util.listUnionElt("time", vars_1);
				filename = Absyn.pathString(className);
				filename = Util.stringAppendList({filename, "_res.plt"});

        value = System.readPtolemyplotDataset(filename, vars_2, 0);

        res = Values.sendPtolemyplotDataset(value, vars_2, "Plot by OpenModelica", interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, Exp.printExpStr(xRange), Exp.printExpStr(yRange));

      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "plot"),
        expLst = {
        Exp.CODE(Absyn.C_TYPENAME(className),_),
        Exp.ARRAY(array = vars),
  			Exp.SCONST(string = interpolation), Exp.SCONST(string = title), Exp.BCONST(bool = legend), Exp.BCONST(bool = grid), Exp.BCONST(bool = logX), Exp.BCONST(bool = logY), Exp.SCONST(string = xLabel), Exp.SCONST(string = yLabel), Exp.BCONST(bool = points), xRange, yRange
        }),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)

      local
        Integer res;
        Exp.Exp xRange, yRange;
        list<Exp.Exp> vars;
        String interpolation, title, xLabel, yLabel;
        Boolean legend, grid, logX, logY, points;
       equation

         vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "plot" ;
        vars_2 = Util.listUnionElt("time", vars_1);
 				filename = Absyn.pathString(className);
				filename = Util.stringAppendList({filename, "_res.plt"});

        failure(_ = System.readPtolemyplotDataset(filename, vars_2, 0));

      then
					(cache,Values.STRING("Error reading the simulation result."),st);

    case (cache,env, //plot2({x,y})
      Exp.CALL(
        path = Absyn.IDENT(name = "plot"),
        expLst = {Exp.ARRAY(array = vars),
  			Exp.SCONST(string = interpolation), Exp.SCONST(string = title), Exp.BCONST(bool = legend), Exp.BCONST(bool = grid), Exp.BCONST(bool = logX), Exp.BCONST(bool = logY), Exp.SCONST(string = xLabel), Exp.SCONST(string = yLabel), Exp.BCONST(bool = points), xRange, yRange
        }),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        Exp.Exp xRange, yRange;
        list<Exp.Exp> vars;
				String interpolation, title, xLabel, yLabel;
				Boolean legend, logX, logY, points;
				Boolean grid;
      equation
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "plot" ;
        vars_2 = Util.listUnionElt("time", vars_1);
        (cache,Values.RECORD(orderd={Values.STRING(filename)}),_) = Ceval.ceval(cache,env,
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, msg);
        value = System.readPtolemyplotDataset(filename, vars_2, 0);
        res = Values.sendPtolemyplotDataset(value, vars_2, "Plot by OpenModelica", interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, Exp.printExpStr(xRange), Exp.printExpStr(yRange));

      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "plot"),
        expLst = {Exp.ARRAY(array = vars),
  			Exp.SCONST(string = interpolation), Exp.SCONST(string = title), Exp.BCONST(bool = legend), Exp.BCONST(bool = grid), Exp.BCONST(bool = logX), Exp.BCONST(bool = logY), Exp.SCONST(string = xLabel), Exp.SCONST(string = yLabel), Exp.BCONST(bool = points), xRange, yRange
        }),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        Exp.Exp xRange, yRange;
        list<Exp.Exp> vars;
				String interpolation, title, xLabel, yLabel;
				Boolean legend, logX, logY, points;
				Boolean grid;

      equation
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        vars_2 = Util.listUnionElt("time", vars_1);
        (cache,Values.RECORD(orderd={Values.STRING(filename)}),_) = Ceval.ceval(cache,env,
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, msg);
        failure(_ = System.readPtolemyplotDataset(filename, vars_2, 0));
      then
        (cache,Values.STRING("Error reading the simulation result."),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "plot"),
        expLst = {Exp.ARRAY(array = vars),
  			Exp.SCONST(string = interpolation), Exp.SCONST(string = title), Exp.BCONST(bool = legend), Exp.BCONST(bool = grid), Exp.BCONST(bool = logX), Exp.BCONST(bool = logY), Exp.SCONST(string = xLabel), Exp.SCONST(string = yLabel), Exp.BCONST(bool = points), xRange, yRange
        }),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        Exp.Exp xRange, yRange;
        list<Exp.Exp> vars;
        String interpolation, title, xLabel, yLabel;
        Boolean legend, grid, logX, logY, points;

      equation
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        vars_2 = Util.listUnionElt("time", vars_1);
        failure((_,_,_) = Ceval.ceval(cache,env,
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, Ceval.NO_MSG()));
      then
        (cache,Values.STRING("No simulation result to plot."),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "plot"),
        expLst = {Exp.ARRAY(array = vars),
  			Exp.SCONST(string = interpolation), Exp.SCONST(string = title), Exp.BCONST(bool = legend), Exp.BCONST(bool = grid), Exp.BCONST(bool = logX), Exp.BCONST(bool = logY), Exp.SCONST(string = xLabel), Exp.SCONST(string = yLabel), Exp.BCONST(bool = points), xRange, yRange
        }),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        Exp.Exp xRange, yRange;
        list<Exp.Exp> vars;
        String interpolation, title, xLabel, yLabel;
        Boolean legend, grid, logX, logY, points;

      then
        (cache,Values.STRING("Unknown error while plotting"),st);


// he-mag, visualize
// visualize(model, x)
    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "visualize"),
        expLst = {
        Exp.CODE(Absyn.C_TYPENAME(className),_)
        }),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        list<String> vars;
        String visvar_str, interpolation, title, xLabel, yLabel;
        Boolean legend, grid, logX, logY, points;
      equation
        print("visualize(model)\n");

        //Här ska jag komma in, bygga en vettig argumentlista till readptol...

        //Jag måste få readptol att skicka alla variabler i .plt-filen, och en idé är
        //att göra en egen enkel funktion som i princip är en grep på DataSet: i filen..
        //Kolla på senddata:emulateStreamData

        //vars = Util.listMap(vars,Exp.CodeVarToCref);
        //vars = Util.listMap(vars, Exp.printExpStr) "plot" ;
        //vars_2 = Util.listUnionElt("time", vars_1);
        //vars = Util.listCreate("visualize");
        visvar_str = Interactive.getElementsOfVisType(className, p);
        //print("varsofvistype: " +& visvar_str +& "\n");
				filename = Absyn.pathString(className);
				filename = Util.stringAppendList({filename, "_res.plt"});
				//print("filename: ");
				//print(filename);
				vars = System.readPtolemyplotVariables(filename, visvar_str);
        vars_2 = Util.listUnionElt("time", vars);
  		  //print(Util.stringAppendList(vars_2));
        //print(Util.stringDelimitList(vars_2, ", "));
        value = System.readPtolemyplotDataset(filename, vars_2, 0);
        res = Values.sendPtolemyplotDataset2(value, vars_2, visvar_str, "Plot by OpenModelica");

      then
        (cache,Values.BOOL(true),st);

/*    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "visualize_"),
        expLst = {
        Exp.CODE(Absyn.C_TYPENAME(className),_)
        }),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)

      local
        Integer res;
        list<String> vars;
        String className,interpolation, title, xLabel, yLabel;
        Boolean legend, grid, logX, logY, points;
       equation

        // vars = Util.listMap(vars,Exp.CodeVarToCref);
        //vars_1 = Util.listMap(vars, Exp.printExpStr) "plot" ;
        //vars_2 = Util.listUnionElt("time", vars_1);
 				filename = Absyn.pathString(className);
				filename = Util.stringAppendList({filename, "_res.plt"});
				vars = System.readPtolemyplotVariables(filename);

        failure(_ = System.readPtolemyplotDataset(filename, vars, 0));

      then
					(cache,Values.STRING("Error reading the simulation result."),st);*/

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "visualize"),
        expLst = {Exp.ARRAY(array = vars),
  			Exp.SCONST(string = interpolation), Exp.SCONST(string = title), Exp.BCONST(bool = legend), Exp.BCONST(bool = grid), Exp.BCONST(bool = logX), Exp.BCONST(bool = logY), Exp.SCONST(string = xLabel), Exp.SCONST(string = yLabel), Exp.BCONST(bool = points)
        }),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        list<Exp.Exp> vars;
				String interpolation, title, xLabel, yLabel, liststr;
				Boolean legend, logX, logY, points;
				Boolean grid;
      equation
        print("hittaderättigen\n");
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "plot" ;
        vars_2 = Util.listUnionElt("time", vars_1);
//        listMap(vars_2, print);
        print(Util.stringAppendList(vars_2));
        (cache,Values.RECORD(orderd={Values.STRING(filename)}),_) = Ceval.ceval(cache,env,
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, msg);
        print("tjo\n");
        value = System.readPtolemyplotDataset(filename, vars_2, 0);
        print("value = " +& Values.valString(value));
        res = Values.sendPtolemyplotDataset(value, vars_2, "Plot by OpenModelica", interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, title, title);

      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "visualize"),
        expLst = {Exp.ARRAY(array = vars),
  			Exp.SCONST(string = interpolation), Exp.SCONST(string = title), Exp.BCONST(bool = legend), Exp.BCONST(bool = grid), Exp.BCONST(bool = logX), Exp.BCONST(bool = logY), Exp.SCONST(string = xLabel), Exp.SCONST(string = yLabel), Exp.BCONST(bool = points)
        }),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        list<Exp.Exp> vars;
				String interpolation, title, xLabel, yLabel;
				Boolean legend, logX, logY, points;
				Boolean grid;

      equation
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        vars_2 = Util.listUnionElt("time", vars_1);
        (cache,Values.RECORD(orderd={Values.STRING(filename)}),_) = Ceval.ceval(cache,env,
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, msg);
        failure(_ = System.readPtolemyplotDataset(filename, vars_2, 0));
      then
        (cache,Values.STRING("Error reading the simulation result."),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "visualize"),
        expLst = {Exp.ARRAY(array = vars),
  			Exp.SCONST(string = interpolation), Exp.SCONST(string = title), Exp.BCONST(bool = legend), Exp.BCONST(bool = grid), Exp.BCONST(bool = logX), Exp.BCONST(bool = logY), Exp.SCONST(string = xLabel), Exp.SCONST(string = yLabel), Exp.BCONST(bool = points)
        }),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        list<Exp.Exp> vars;
        String interpolation, title, xLabel, yLabel;
        Boolean legend, grid, logX, logY, points;

      equation
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        vars_2 = Util.listUnionElt("time", vars_1);
        failure((_,_,_) = Ceval.ceval(cache,env,
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, Ceval.NO_MSG()));
      then
        (cache,Values.STRING("No simulation result to plot."),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "visualize"),
        expLst = {Exp.ARRAY(array = vars),
  			Exp.SCONST(string = interpolation), Exp.SCONST(string = title), Exp.BCONST(bool = legend), Exp.BCONST(bool = grid), Exp.BCONST(bool = logX), Exp.BCONST(bool = logY), Exp.SCONST(string = xLabel), Exp.SCONST(string = yLabel), Exp.BCONST(bool = points)
        }),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        list<Exp.Exp> vars;
        String interpolation, title, xLabel, yLabel;
        Boolean legend, grid, logX, logY, points;
      then
        (cache,Values.STRING("Unknown error while plotting"),st);


// } visualize

/* adpo: val OpenModelica version:
    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "val"),
        expLst = {Exp.ARRAY(array = {varName, varTimeStamp})}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Exp.Exp varName, varTimeStamp;
        String var;
        Integer res;
        Real timeStamp;
        list<Values.Value> varValues, timeValues;
        list<Real> tV, vV;
        Real val;
      equation

        {varName} = Util.listMap({varName},Exp.CodeVarToCref);
        vars_1 = Util.listMap({varName}, Exp.printExpStr);
        // Util.listMap0(vars_1,print);

        (cache,Values.REAL(timeStamp),SOME(st)) = Ceval.ceval(cache,env, varTimeStamp, true, SOME(st), NONE, msg);

        (cache,Values.RECORD(orderd={Values.STRING(filename)}),_) = Ceval.ceval(cache,env,
        Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, msg);

        Values.ARRAY({Values.ARRAY(varValues)}) = System.readPtolemyplotDataset(filename, vars_1, 0);
        Values.ARRAY({Values.ARRAY(timeValues)}) = System.readPtolemyplotDataset(filename, {"time"}, 0);


        tV = Values.valueReals(timeValues);
        vV = Values.valueReals(varValues);
        val = System.getVariableValue(timeStamp, tV, vV);
      then
        (cache,Values.REAL(val),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "val"),
        expLst = {Exp.ARRAY(array = {varName, varTimeStamp})}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Exp.Exp varName, varTimeStamp;
        String var;
        Integer res;
        Integer timeStamp;
        list<Values.Value> varValues, timeValues;
        list<Real> tV, vV;
        Real val;
      equation

        {varName} = Util.listMap({varName},Exp.CodeVarToCref);
        vars_1 = Util.listMap({varName}, Exp.printExpStr);
        // Util.listMap0(vars_1,print);

        (cache,Values.INTEGER(timeStamp),SOME(st)) = Ceval.ceval(cache,env, varTimeStamp, true, SOME(st), NONE, msg);

        (cache,Values.RECORD(orderd={Values.STRING(filename)}),_) = Ceval.ceval(cache,env,
        Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, msg);

        Values.ARRAY({Values.ARRAY(varValues)}) = System.readPtolemyplotDataset(filename, vars_1, 0);
        Values.ARRAY({Values.ARRAY(timeValues)}) = System.readPtolemyplotDataset(filename, {"time"}, 0);


        tV = Values.valueReals(timeValues);
        vV = Values.valueReals(varValues);
        val = System.getVariableValue(intReal(timeStamp), tV, vV);
      then
        (cache,Values.REAL(val),st);
*/   

     case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "val"),
        expLst = {varName, varTimeStamp}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local 
        Exp.Exp varName, varTimeStamp;
        Real timeStamp;               
        Real val;
        String varNameStr;
      equation         
        varName = Exp.CodeVarToCref(varName);
        varNameStr = Exp.printExpStr(varName);        
        (cache,Values.REAL(timeStamp),SOME(st)) = Ceval.ceval(cache,env, varTimeStamp, true, SOME(st), NONE, msg);
        (cache,val) = cevalVal(cache,env,SOME(st),timeStamp,varNameStr);                       
      then
        (cache,Values.REAL(val),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "val"),
        expLst = {varName, varTimeStamp}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local 
        Exp.Exp varName, varTimeStamp;
        Integer timeStampI;
        Real timeStamp;               
        Real val;
        String varNameStr;
      equation         
        varName = Exp.CodeVarToCref(varName);
        varNameStr = Exp.printExpStr(varName);        
        (cache,Values.INTEGER(timeStampI),SOME(st)) = Ceval.ceval(cache,env, varTimeStamp, true, SOME(st), NONE, msg);
        timeStamp = intReal(timeStampI);        
        (cache,val) = cevalVal(cache,env,SOME(st),timeStamp,varNameStr);                       
      then
        (cache,Values.REAL(val),st);        
        
    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "val"),
        expLst = {varName, varTimeStamp}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local 
        Exp.Exp varName, varTimeStamp;
        Integer timeStampI;
        Real timeStamp;               
        Values.Value val;
        String varNameStr;
        list<Values.Value> vals;
        list<Real> timeStamps;
      equation         
        varName = Exp.CodeVarToCref(varName);
        varNameStr = Exp.printExpStr(varName);        
        (cache,Values.ARRAY(vals),SOME(st)) = Ceval.ceval(cache,env, varTimeStamp, true, SOME(st), NONE, msg);               
         timeStamps = Util.listMap(vals,Values.valueReal);
        (cache,val) = cevalValArray(cache,env,SOME(st),timeStamps,varNameStr);                       
      then
        (cache,val,st);        
     
    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "val"),
        expLst = {Exp.ARRAY(array = vars)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)      
      local 
        list<Exp.Exp> vars;
      then
        (cache,Values.STRING("Error, check variable name and time variables"),st);
        
        
    /* plotparametric This rule represents the normal case when an array of at least two elements 
     *  is given as an argument  
     */
    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "plotParametric2"),expLst = vars),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)  
      local
        Integer res;
        list<Exp.Exp> vars;
        String uniqueStr;
      equation 
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr);
        length = listLength(vars_1);
        (length > 1) = true;
        (cache,Values.RECORD(orderd={Values.STRING(filename)}),_) = Ceval.ceval(cache,env, 
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, msg);
        value = System.readPtolemyplotDataset(filename, vars_1, 0);
        pwd = System.pwd();
        cit = winCitation();
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.trim(omhome, "\"");
        pd = System.pathDelimiter();
        plotCmd = Util.stringAppendList({cit,omhome_1,pd,"bin",pd,"doPlot",cit});
        uniqueStr = intString(tick());
        tmpPlotFile = Util.stringAppendList({pwd,pd,"tmpPlot_",uniqueStr,".plt"});
        res = Values.writePtolemyplotDataset(tmpPlotFile, value, vars_1, "Plot by OpenModelica");
        call = Util.stringAppendList({cit,plotCmd," \"",tmpPlotFile,"\"",cit});
        _ = System.systemCall(call);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "plotParametric2"),expLst = vars),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      equation
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error with less than two elements (=variables) in the array.
           This means we cannot plot var2 as a function of var1 as var2 is missing" ;
        length = listLength(vars_1);
        (length < 2) = true;
      then
        (cache,Values.STRING("Error: Less than two variables given to plotParametric."),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "plotParametric2"),expLst = vars),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      equation
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        (cache,Values.RECORD(orderd={Values.STRING(filename)}),_) = Ceval.ceval(cache,env,
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, msg) "Util.list_union_elt(\"time\",vars\') => vars\'\' &" ;
        failure(_ = System.readPtolemyplotDataset(filename, vars_1, 0));
      then
        (cache,Values.STRING("Error reading the simulation result."),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "plotParametric2"),expLst = vars),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      equation
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        failure((_,_,_) = Ceval.ceval(cache,env,
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, Ceval.NO_MSG())) "Util.list_union_elt(\"time\",vars\') => vars\'\' &" ;
      then
        (cache,Values.STRING("No simulation result to plot."),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "plotParametric2"),expLst = vars),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      then
        (cache,Values.STRING("Unknown error while plotting"),st);
    /* end plotparametric */

//plotParametric2(modell, x,y,interpolation)
    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "plotParametric"),
      expLst = {   Exp.CODE(Absyn.C_TYPENAME(className),_),
        Exp.ARRAY(array = vars),
  			Exp.SCONST(string = interpolation), Exp.SCONST(string = title), Exp.BCONST(bool = legend), Exp.BCONST(bool = grid), Exp.BCONST(bool = logX), Exp.BCONST(bool = logY), Exp.SCONST(string = xLabel), Exp.SCONST(string = yLabel), Exp.BCONST(bool = points), xRange, yRange
        }),

      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        Exp.Exp xRange, yRange;
        list<Exp.Exp> vars;
        String interpolation, title, xLabel, yLabel, uniqueStr;
        Boolean legend, grid, logX, logY, points;        
      equation
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr);
        length = listLength(vars_1);
        (length > 1) = true;
				filename = Absyn.pathString(className);
				filename = Util.stringAppendList({filename, "_res.plt"});

        value = System.readPtolemyplotDataset(filename, vars_1, 0);
        pwd = System.pwd();
        cit = winCitation();
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.trim(omhome, "\"");
        pd = System.pathDelimiter();
        plotCmd = Util.stringAppendList({cit,omhome_1,pd,"bin",pd,"doPlot",cit});
        uniqueStr = intString(tick());
        tmpPlotFile = Util.stringAppendList({pwd,pd,"tmpPlot_",uniqueStr,".plt"});
        res = Values.sendPtolemyplotDataset(value, vars_1, "Plot by OpenModelica", interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, Exp.printExpStr(xRange), Exp.printExpStr(yRange));
      then
        (cache,Values.BOOL(true),st);

//plotParametric2(x,y,interpolation)
   case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "plotParametric"),
      expLst = {Exp.ARRAY(array = vars),
  			Exp.SCONST(string = interpolation), Exp.SCONST(string = title), Exp.BCONST(bool = legend), Exp.BCONST(bool = grid), Exp.BCONST(bool = logX), Exp.BCONST(bool = logY), Exp.SCONST(string = xLabel), Exp.SCONST(string = yLabel), Exp.BCONST(bool = points), xRange, yRange

      }),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local
        Integer res;
        Exp.Exp xRange, yRange;
        list<Exp.Exp> vars;
        String interpolation, title, xLabel, yLabel;
        Boolean legend, grid, logX, logY, points;
      equation

        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr);
        length = listLength(vars_1);
        (length > 1) = true;
        (cache,Values.RECORD(orderd={Values.STRING(filename)}),_) = Ceval.ceval(cache,env,
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, msg);
         value = System.readPtolemyplotDataset(filename, vars_1, 0);
         res = Values.sendPtolemyplotDataset(value, vars_1, "Plot by OpenModelica", interpolation, title, legend, grid, logX, logY, xLabel, yLabel, points, Exp.printExpStr(xRange), Exp.printExpStr(yRange));

      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "plotParametric"),expLst = vars),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      equation
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        failure((_,_,_) = Ceval.ceval(cache,env,
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, Ceval.NO_MSG())) "Util.list_union_elt(\"time\",vars\') => vars\'\' &" ;
      then
        (cache,Values.STRING("No simulation result to plot."),st);


    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "plotParametric"),expLst = vars),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      equation 
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error with less than two elements (=variables) in the array.
           This means we cannot plot var2 as a function of var1 as var2 is missing" ;
        length = listLength(vars_1);
        (length < 2) = true;
      then
        (cache,Values.STRING("Error: Less than two variables given to plotParametric."),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "plotParametric"),expLst = vars),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      equation 
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        (cache,Values.RECORD(orderd={Values.STRING(filename)}),_) = Ceval.ceval(cache,env, 
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, msg) "Util.list_union_elt(\"time\",vars\') => vars\'\' &" ;
        failure(_ = System.readPtolemyplotDataset(filename, vars_1, 0));
      then
        (cache,Values.STRING("Error reading the simulation result."),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "plotParametric"),expLst = vars),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      equation 
        vars = Util.listMap(vars,Exp.CodeVarToCref);
        vars_1 = Util.listMap(vars, Exp.printExpStr) "Catch error reading simulation file." ;
        failure((_,_,_) = Ceval.ceval(cache,env, 
          Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, Ceval.NO_MSG())) "Util.list_union_elt(\"time\",vars\') => vars\'\' &" ;
      then
        (cache,Values.STRING("No simulation result to plot."),st);

    case (cache,env,
      Exp.CALL(path = Absyn.IDENT(name = "plotParametric"),expLst = vars),
      (st as Interactive.SYMBOLTABLE(
        ast = p,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local list<Exp.Exp> vars;
      then
        (cache,Values.STRING("Unknown error while plotting"),st);
    /* end plotparametric */        

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "enableSendData"),expLst = {Exp.BCONST(bool = b)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local
        Boolean b;
      equation
//        print("enableSendData\n");
//        print(Util.boolString(b));
//        print("\n");
        System.enableSendData(b);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "setDataPort"),expLst = {Exp.ICONST(integer = i)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local
        Integer i;
      equation
//        print("setDataPort\n");
//        print(intString(i));
//        print("\n");
        System.setDataPort(i);
      then
        (cache,Values.BOOL(true),st);
        //{Exp.ARRAY(array = strings)}
    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "setVariableFilter"),expLst = {Exp.ARRAY(array=strings)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local
        list<Exp.Exp> strings;
      equation
        vars_1 = Util.listMap(strings, Exp.printExpStr);
//        print("setVariableFilter\n");
//        print(Util.stringAppendList(vars_1));
 //       print("\n");
//        _ = Values.setVariableFilter(vars_1);
        _=System.setVariableFilter(Util.stringAppendList(vars_1));
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "timing"),expLst = {exp}),st,msg)  
      equation 
        t1 = System.time();
        (cache,value,SOME(st_1)) = Ceval.ceval(cache,env, exp, true, SOME(st), NONE, msg);
        t2 = System.time();
        time = t2 -. t1;
      then
        (cache,Values.REAL(time),st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "setCompiler"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        System.setCCompiler(str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "setCompilerFlags"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        System.setCFlags(str);
      then
        (cache,Values.BOOL(true),st);

     case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "setLinker"),expLst = {Exp.SCONST(string = str)}),st,msg)
      equation 
        System.setLinker(str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "setLinkerFlags"),expLst = {Exp.SCONST(string = str)}),st,msg)
      equation 
        System.setLDFlags(str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "setDebugFlags"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str_1 = stringAppend("+d=", str);
        args = RTOpts.args({str_1});
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "cd"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local Integer res;
      equation 
        res = System.cd(str);
        (res == 0) = true;
        str_1 = System.pwd();
      then
        (cache,Values.STRING(str_1),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "cd"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* no such directory */ 
      equation 
        failure(0 = System.directoryExists(str));
        res = Util.stringAppendList({"Error, directory ",str," does not exist,"});
      then
        (cache,Values.STRING(res),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "cd"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str_1 = System.pwd();
      then
        (cache,Values.STRING(str_1),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getVersion"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str_1 = Settings.getVersionNr();
      then
        (cache,Values.STRING(str_1),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getTempDirectoryPath"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str_1 = Settings.getTempDirectoryPath();
      then
        (cache,Values.STRING(str_1),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "system"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local Integer res;
      equation 
        res = System.systemCall(str);
      then
        (cache,Values.INTEGER(res),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "readFile"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str_1 = System.readFile(str);
      then
        (cache,Values.STRING(str_1),st);
        
    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "readFileNoNumeric"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str_1 = System.readFileNoNumeric(str);
      then
        (cache,Values.STRING(str_1),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getErrorString"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str = Error.printMessagesStr();
      then
        (cache,Values.STRING(str),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getMessagesString"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* New error message implementation */ 
      equation 
        str = Error.printMessagesStr();
      then
        (cache,Values.STRING(str),st);
     
    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "clearMessages"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)  
      equation 
        Error.clearMessages();
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getMessagesStringInternal"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str = Error.getMessagesStr();
      then
        (cache,Values.STRING(str),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "runScript"),expLst = {Exp.SCONST(string = str)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local String msg;
      equation 
        scriptstr = System.readFile(str);
        (istmts,msg) = Parser.parsestringexp(scriptstr);
        equality(msg = "Ok");
        (res,newst) = Interactive.evaluate(istmts, st, true);
        res_1 = Util.stringAppendList({res,"\ntrue"});
      then
        (cache,Values.STRING(res_1),newst);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "runScript"),expLst = {Exp.SCONST(string = str)}),st,msg) then (cache,Values.BOOL(false),st); 

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "generateCode"),expLst = {Exp.CODE(Absyn.C_TYPENAME(path),_)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        (cache,_) = cevalGenerateFunction(cache,env, path) "	& Inst.instantiate_implicit(p\') => d &" ;
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "loadModel"),
        expLst = {Exp.CODE(Absyn.C_TYPENAME(path),_)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,depends=aDep,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg) /* add path to symboltable for compiled functions
	  Interactive.SYMBOLTABLE(p,sp,ic,iv,(path,t)::cf),
	  but where to get t? */ 
      local Absyn.Program p_1;
      equation 
        mp = Settings.getModelicaPath();
        pnew = ClassLoader.loadClass(path, mp);
        p_1 = Interactive.updateProgram(pnew, p);
        str = Print.getString();
        newst = Interactive.SYMBOLTABLE(p_1,aDep,sp,{},iv,cf,lf);
      then
        (cache,Values.BOOL(true),newst);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "loadModel"),expLst = {Exp.CODE(Absyn.C_TYPENAME(path),_)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        pathstr = ModUtil.pathString(path);
        Error.addMessage(Error.LOAD_MODEL_ERROR, {pathstr});
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "loadModel"),expLst = {Exp.CODE(Absyn.C_TYPENAME(path),_)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) 
    then (cache,Values.BOOL(false),st);  /* loadModel failed */ 

    case (cache,env,
      Exp.CALL(
        path = Absyn.IDENT(name = "loadFile"),
        expLst = {Exp.SCONST(string = name)}),
      (st as Interactive.SYMBOLTABLE(
        ast = p,depends=aDep,explodedAst = sp,instClsLst = ic,
        lstVarVal = iv,compiledFunctions = cf,
        loadedFiles = lf)),msg)
      local Absyn.Program p1;
      equation 
        p1 = ClassLoader.loadFile(name) "System.regularFileExists(name) => 0 & Parser.parse(name) => p1 &" ;
        newp = Interactive.updateProgram(p1, p);
      then
        (cache,Values.BOOL(true),Interactive.SYMBOLTABLE(newp,aDep,sp,ic,iv,cf,lf));

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "loadFile"),expLst = {Exp.SCONST(string = name)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* (Values.BOOL(true),Interactive.SYMBOLTABLE(newp,sp,{},iv,cf)) it the rule above have failed then check if file exists without this omc crashes */ 
      equation 
        rest = System.regularFileExists(name);
        (rest > 0) = true;
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "loadFile"),expLst = {Exp.SCONST(string = name)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) /* not Parser.parse(name) => _ */  
    then (cache,Values.BOOL(false),st); 

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "saveModel"),expLst = {Exp.SCONST(string = filename),Exp.CODE(Absyn.C_TYPENAME(classpath),_)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation        
        class_ = Interactive.getPathedClassInProgram(classpath, p);
        str = Dump.unparseStr(Absyn.PROGRAM({class_},Absyn.TOP(),Absyn.TIMESTAMP(0.0,0.0)),true) ;
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);
        
    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "saveTotalModel"),expLst = {Exp.SCONST(string = filename),Exp.CODE(Absyn.C_TYPENAME(classpath),_)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local AbsynDep.Depends dep; AbsynDep.AvlTree uses;
      equation 
        class_ = Interactive.getPathedClassInProgram(classpath, p);
        ptot = Interactive.getTotalProgram(classpath,p);
        str = Dump.unparseStr(ptot,true);
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);        

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "saveModel"),expLst = {Exp.SCONST(string = name),Exp.CREF(componentRef = cr)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        classpath = Static.componentRefToPath(cr) "Error writing to file" ;
        class_ = Interactive.getPathedClassInProgram(classpath, p);
        str = Dump.unparseStr(Absyn.PROGRAM({class_},Absyn.TOP(),Absyn.TIMESTAMP(0.0,0.0)),true);
        Error.addMessage(Error.WRITING_FILE_ERROR, {name});
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "save"),expLst = {Exp.CODE(Absyn.C_TYPENAME(className),_)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local Absyn.Program p_1;
      equation 
        (p_1,filename) = Interactive.getContainedClassAndFile(className, p);
        str = Dump.unparseStr(p_1,true);
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "save"),expLst = {Exp.CODE(Absyn.C_TYPENAME(className),_)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg) 
    then (cache,Values.BOOL(false),st); 

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "saveAll"),expLst = {Exp.SCONST(string = filename)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        str = Dump.unparseStr(p,true);
        System.writeFile(filename, str);
      then
        (cache,Values.BOOL(true),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "saveModel"),expLst = {Exp.SCONST(string = name),Exp.CODE(Absyn.C_TYPENAME(classpath),_)}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        cname = Absyn.pathString(classpath);
        Error.addMessage(Error.LOOKUP_ERROR, {cname,"global"});
      then
        (cache,Values.BOOL(false),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "help"),expLst = {}),(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.trim(omhome, "\"");
        cit = winCitation();
        pd = System.pathDelimiter();
        filename = Util.stringAppendList({omhome_1,pd,"bin",pd,"omc_helptext.txt"});
        print(filename);
        str = System.readFile(filename);
      then
        (cache,Values.STRING(str),st);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getUnit"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "unit", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getQuantity"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "quantity", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getDisplayUnit"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "displayUnit", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getMin"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "min", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getMax"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "max", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getStart"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "start", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getFixed"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "fixed", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getNominal"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "nominal", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "getStateSelect"),expLst = {Exp.CREF(componentRef = cref),Exp.CREF(componentRef = classname)}),st,msg)
      equation 
        (cache,v,st_1) = getBuiltinAttribute(cache,classname, cref, "stateSelect", st);
      then
        (cache,v,st_1);

    case (cache,env,Exp.CALL(path = Absyn.IDENT(name = "echo"),expLst = {bool_exp}),st,msg)
      equation 
        (cache,(v as Values.BOOL(bval)),SOME(st_1)) = Ceval.ceval(cache,env, bool_exp, true, SOME(st), NONE, msg);
        setEcho(bval);
      then
        (cache,v,st);
    case (cache,env,(exp as
      Exp.CALL(
        path = Absyn.IDENT(name = "dumpXMLDAE"),
        expLst =
        {Exp.CODE(Absyn.C_TYPENAME(className),_),
         asInSimulationCode,
         addOriginalIncidenceMatrix,
         addSolvingInfo,         
         addMathMLCode,
         dumpResiduals,
         filenameprefix,
         storeInTemp})),
      (st_1 as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg)
        local
          String xml_filename,xml_contents;
      equation
        (cache,st,xml_filename,xml_contents) = dumpXMLDAE(cache,env, exp, st_1, msg);
      then
        (cache,Values.ARRAY({Values.STRING(xml_filename),Values.STRING(xml_contents)}),st);

    case (cache,env,(exp as
      Exp.CALL(
        path = Absyn.IDENT(name = "dumpXMLDAE"),
        expLst =
        {
        Exp.CODE(Absyn.C_TYPENAME(className),_),
        asInSimulationCode,
        addOriginalIncidenceMatrix,
        addSolvingInfo,        
        addMathMLCode,
        dumpResiduals,
        filenameprefix,
        storeInTemp})),
      (st_1 as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = iv,
        compiledFunctions = cf)),msg) /* failing build_model */
    then (cache,Values.ARRAY({Values.STRING("Xml dump error"),Values.STRING("")}),st_1);
  end matchcontinue;
end cevalInteractiveFunctions;

protected function setEcho 
  input Boolean echo;
algorithm
  _:=
  matchcontinue (echo)
    local
    case (true)
      equation 
        Settings.setEcho(1);
      then
        ();
    case (false)
      equation 
        Settings.setEcho(0);
      then
        ();
  end matchcontinue; 
end setEcho;

protected function cevalValArray "Help function to cevalInteractiveFunctions. Handles val(var,{timestamps})"
	input Env.Cache cache;
	input Env.Env env;
  input Option<Interactive.InteractiveSymbolTable> st;
	input list<Real> timeStamps;
	input String varName;
	output Env.Cache outCache;
	output Values.Value value;
algorithm
  (outCache,value) := matchcontinue(cache,env,st,timeStamps,varName)
  local list<Values.Value> vals;
    Real v,timeStamp;
    case(cache,env,st,{},varName) then (cache,Values.ARRAY({}));
    case(cache,env,st,timeStamp::timeStamps,varName) equation
      (cache,v) = cevalVal(cache,env,st,timeStamp,varName);
      (cache,Values.ARRAY(vals)) = cevalValArray(cache,env,st,timeStamps,varName);
    then (cache,Values.ARRAY(Values.REAL(v)::vals));
  end matchcontinue;
end cevalValArray;

protected function cevalVal "Help function to cevalInteractiveFunctions. Handles val(var,timestamp)"
	input Env.Cache cache;
	input Env.Env env;
  input Option<Interactive.InteractiveSymbolTable> stopt;
	input Real timeStamp;
	input String varName;
	output Env.Cache outCache;
	output Real value;
algorithm
  (outCache,value) := matchcontinue(cache,env,st,timeStamp,varName)
  local Real val; list<Real> tV, vV; list<Values.Value> varValues, timeValues;
    Interactive.InteractiveSymbolTable st;
    String filename;
    case(cache,env,SOME(st),timeStamp,varName) equation            
      (cache,Values.RECORD(orderd={Values.STRING(filename)}),_) = Ceval.ceval(cache,env, 
        Exp.CREF(Exp.CREF_IDENT("currentSimulationResult",Exp.OTHER(),{}),Exp.OTHER()), true, SOME(st), NONE, Ceval.NO_MSG());
      
      Values.ARRAY({Values.ARRAY(varValues)}) = System.readPtolemyplotDataset(filename, {varName}, 0);
      Values.ARRAY({Values.ARRAY(timeValues)}) = System.readPtolemyplotDataset(filename, {"time"}, 0); 
      
      tV = Values.valueReals(timeValues);
      vV = Values.valueReals(varValues);  
      val = System.getVariableValue(timeStamp, tV, vV);                
      then (cache,val);       
  end matchcontinue;
end cevalVal;

public function getIncidenceMatrix "function getIncidenceMatrix
 author: adrpo
 translates a model and returns the incidence matrix"
	input Env.Cache inCache;
	input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  input Exp.Exp inExp;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
  output String outString;
algorithm 
  (outCache,outValue,outInteractiveSymbolTable,outString):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg,inExp)
    local
      String filenameprefix,cname_str,filename,funcfilename,makefilename,file_dir, str;
      Absyn.Path classname;
      list<SCode.Class> p_1,sp;
      DAE.DAElist dae_1,dae;
      list<Env.Frame> env;
      list<DAE.Element> dael;
      list<Interactive.InstantiatedClass> ic_1,ic;
      DAELow.DAELow dlow,dlow_1,indexed_dlow,indexed_dlow_1;
      list<Integer>[:] m,mT;
      Integer[:] ass1,ass2;
      list<list<Integer>> comps;
      Absyn.ComponentRef a_cref;
      list<String> libs;
      Exp.ComponentRef cr;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p,ptot;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      Exp.Exp fileprefix;
      Env.Cache cache;
      Integer elimLevel;
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg,fileprefix) /* mo file directory */ 
      local
        String flatModelicaStr;
      equation 
        (cache,filenameprefix) = extractFilePrefix(cache,env, fileprefix, st, msg);
        p_1 = SCode.elaborate(p);
        (cache,env,_,dae_1) = 
        Inst.instantiateClass(cache,InstanceHierarchy.emptyInstanceHierarchy,p_1,className);
        ((dae as DAE.DAE(dael))) = DAE.transformIfEqToExpr(dae_1);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dael,env));
        a_cref = Absyn.pathToCref(className);
        file_dir = getFileDir(a_cref, p);
        elimLevel = RTOpts.eliminationLevel();
        RTOpts.setEliminationLevel(0); // No variable eliminiation
        dlow = DAELow.lower(dae, false, false);
        RTOpts.setEliminationLevel(elimLevel); // Reset elimination level
        flatModelicaStr = DAE.dumpStr(dae);
        flatModelicaStr = stringAppend("OldEqStr={'", flatModelicaStr);
        flatModelicaStr = System.stringReplace(flatModelicaStr, "\n", "%##%");
        flatModelicaStr = System.stringReplace(flatModelicaStr, "%##%", "','");
        flatModelicaStr = stringAppend(flatModelicaStr,"'};");
        filename = DAEQuery.writeIncidenceMatrix(dlow, filenameprefix, flatModelicaStr);
        str = stringAppend("The equation system was dumped to Matlab file:", filename);
      then
        (cache,Values.STRING(str),st,file_dir);
  end matchcontinue;
end getIncidenceMatrix;


public function translateModel "function translateModel
 author: x02lucpo
 translates a model into cpp code and writes also a makefile"
	input Env.Cache inCache;
	input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  input Exp.Exp inExp;
  input Boolean addDummy "if true, add a dummy state";
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
  output DAELow.DAELow outDAELow;
  output list<String> outStringLst;
  output String outString;
algorithm 
  (outCache,outValue,outInteractiveSymbolTable,outDAELow,outStringLst,outString):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg,inExp,addDummy)
    local
      String filenameprefix,cname_str,filename,funcfilename,makefilename,file_dir;
      Absyn.Path classname;
      list<SCode.Class> p_1,sp;
      DAE.DAElist dae_1,dae;
      list<Env.Frame> env;
      list<DAE.Element> dael;
      list<Interactive.InstantiatedClass> ic_1,ic;
      DAELow.DAELow dlow,dlow_1,indexed_dlow,indexed_dlow_1;
      list<Integer>[:] m,mT;
      Integer[:] ass1,ass2;
      list<list<Integer>> comps;
      Absyn.ComponentRef a_cref;
      list<String> libs;
      Exp.ComponentRef cr;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p,ptot;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      Exp.Exp fileprefix;
      Env.Cache cache;
      String MakefileHeader;
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg,fileprefix,addDummy) /* mo file directory */ 
      equation 
        (cache,filenameprefix) = extractFilePrefix(cache,env, fileprefix, st, msg);
        ptot = Interactive.getTotalProgram(className,p);
        p_1 = SCode.elaborate(ptot);
        (cache,env,_,dae as DAE.DAE(dael)) = 
        Inst.instantiateClass(cache,InstanceHierarchy.emptyInstanceHierarchy,p_1,className);
        ((dae as DAE.DAE(dael))) = DAE.transformIfEqToExpr(dae);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dael,env));
        dlow = DAELow.lower(dae, addDummy, true);
        Debug.fprint("bltdump", "Lowered DAE:\n");
        Debug.fcall("bltdump", DAELow.dump, dlow);
        m = DAELow.incidenceMatrix(dlow);
        mT = DAELow.transposeMatrix(m);
        (ass1,ass2,dlow_1,m,mT) = DAELow.matchingAlgorithm(dlow, m, mT, (DAELow.INDEX_REDUCTION(),DAELow.EXACT(),DAELow.REMOVE_SIMPLE_EQN()));
        (comps) = DAELow.strongComponents(m, mT, ass1, ass2);
        indexed_dlow = DAELow.translateDae(dlow_1,NONE);
        indexed_dlow_1 = DAELow.calculateValues(indexed_dlow);
        Debug.fprint("bltdump", "indexed DAE:\n");
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrix, m);
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrixT, mT);
        Debug.fcall("bltdump", DAELow.dump, indexed_dlow_1);
        Debug.fcall("bltdump", DAELow.dumpMatching, ass1);
        cname_str = Absyn.pathString(className);
        filename = Util.stringAppendList({filenameprefix,".cpp"});
        Debug.fprintln("dynload", "translateModel: Generating simulation code and functions.");
        funcfilename = Util.stringAppendList({filenameprefix,"_functions.cpp"});
        makefilename = generateMakefilename(filenameprefix);
        a_cref = Absyn.pathToCref(className);
        file_dir = getFileDir(a_cref, p);
        libs = SimCodegen.generateFunctions(p_1, dae, indexed_dlow_1, className, funcfilename);
        SimCodegen.generateSimulationCode(dae, /* dlow_1,*/ indexed_dlow_1, ass1, ass2, m, mT, comps, className, filename, funcfilename,file_dir);
        SimCodegen.generateMakefile(makefilename, filenameprefix, libs, file_dir);
        /* 
        s_call = Util.stringAppendList({"make -f ",cname_str, ".makefile\n"}) 
        */
      then
        (cache,Values.STRING("The model has been translated"),st,indexed_dlow_1,libs,file_dir);
  end matchcontinue;
end translateModel;


public function translateGraphics "function: translates the graphical annotations from old to new version"
	input Env.Cache inCache;
	input Env.Env inEnv;
  input Absyn.Path className;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outCache,outValue,outInteractiveSymbolTable):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg)
    local
      String filenameprefix,cname_str,filename,funcfilename,makefilename,file_dir;
      Absyn.Path classname;
      list<SCode.Class> p_1,sp;
      DAE.DAElist dae_1,dae;
      list<Env.Frame> env;
      list<DAE.Element> dael;
      list<Interactive.InstantiatedClass> ic_1,ic;
      DAELow.DAELow dlow,dlow_1,indexed_dlow,indexed_dlow_1;
      list<Integer>[:] m,mT;
      Integer[:] ass1,ass2;
      list<list<Integer>> comps;
      Absyn.ComponentRef a_cref;
      list<String> libs;
      Exp.ComponentRef cr;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      Exp.Exp fileprefix;
      Env.Cache cache;
      list<Interactive.LoadedFile> lf;
      Absyn.TimeStamp ts;
      AbsynDep.Depends aDep;

    case (cache,env,className,(st as Interactive.SYMBOLTABLE(p as Absyn.PROGRAM(globalBuildTimes=ts),aDep,sp,ic,iv,cf,lf)),msg)  
      local Integer eqnSize,varSize,simpleEqnSize;
        String eqnSizeStr,varSizeStr,retStr,classNameStr,simpleEqnSizeStr,s1;
        DAELow.EquationArray eqns;
        Absyn.Class cls, refactoredClass;
        Absyn.Within within_;
        Integer elimLevel;
        Absyn.Program p1;
        list<Interactive.CompiledCFunction> newCF;
      equation         
	  		cls = Interactive.getPathedClassInProgram(className, p);        
        refactoredClass = Refactor.refactorGraphicalAnnotation(p, cls);
        within_ = Interactive.buildWithin(className);
        p1 = Interactive.updateProgram(Absyn.PROGRAM({refactoredClass}, within_,ts), p);
        s1 = Absyn.pathString(className);
				retStr=Util.stringAppendList({"Translation of ",s1," successful.\n"});
      then
        (cache,Values.STRING(retStr),Interactive.SYMBOLTABLE(p1,aDep,sp,ic,iv,cf,lf));
        
    case (cache,_,_,st,_) local
      String errorMsg; Boolean strEmpty;
      equation
      errorMsg = Error.printMessagesStr();
      strEmpty = (System.strcmp("",errorMsg)==0);
      errorMsg = Util.if_(strEmpty,"Internal error, translating graphics to new version",errorMsg);
    then (cache,Values.STRING(errorMsg),st);  

  end matchcontinue;
end translateGraphics; 

protected function calculateSimulationSettings "function calculateSimulationSettings
 author: x02lucpo
 calculates the start,end,interval,stepsize, method and initFileName"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  input String inString;
  output Env.Cache outCache;
  output String outString1 "filename";
  output Real outReal2 "start time";
  output Real outReal3 "stop time";
  output Real outReal4 "step size";
  output Real tolerance "tolerance";
  output String outString5 "method";
  output String optionsStr;
algorithm 
  (outCache,outString1,outReal2,outReal3,outReal4,tolerance,outString5,optionsStr):=
  matchcontinue (inCache,inEnv,inExp,inInteractiveSymbolTable,inMsg,inString)
    local
      String prefix_str,method_str,init_filename,cname_str,options_str;
      Interactive.InteractiveSymbolTable st;
      Values.Value starttime_v,stoptime_v,tolerance_v;
      Integer interval_i;
      Real starttime_r,stoptime_r,interval_r,tolerance_r;
      list<Env.Frame> env;
      Exp.ComponentRef cr;
      Exp.Exp starttime,stoptime,interval,toleranceExp,method,options,filenameprefix;
      Absyn.Program p;
      list<SCode.Class> sp;
      list<Interactive.InstantiatedClass> ic;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      Env.Cache cache;
      Absyn.Path className;
    case (cache,env,Exp.CALL(expLst = {Exp.CODE(Absyn.C_TYPENAME(className),_),starttime,stoptime,interval,toleranceExp,method,filenameprefix,_,_,options}),
         (st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg,cname_str)
      equation 
        (cache,Values.STRING(prefix_str),SOME(st)) = Ceval.ceval(cache,env, filenameprefix, true, SOME(st), NONE, msg);
        (cache,starttime_v,SOME(st)) = Ceval.ceval(cache,env, starttime, true, SOME(st), NONE, msg);
        (cache,stoptime_v,SOME(st)) = Ceval.ceval(cache,env, stoptime, true, SOME(st), NONE, msg);        
        (cache,Values.INTEGER(interval_i),SOME(st)) = Ceval.ceval(cache,env, interval, true, SOME(st), NONE, msg);
        (cache,tolerance_v,SOME(st)) = Ceval.ceval(cache,env, toleranceExp, true, SOME(st), NONE, msg);
        (cache,Values.STRING(method_str),SOME(st)) = Ceval.ceval(cache,env, method, true, SOME(st), NONE, msg);
        (cache,Values.STRING(options_str),SOME(st)) = Ceval.ceval(cache,env, options, true, SOME(st), NONE, msg);
        starttime_r = Values.valueReal(starttime_v);
        stoptime_r = Values.valueReal(stoptime_v);
        interval_r = intReal(interval_i);
        tolerance_r = Values.valueReal(tolerance_v);
        init_filename = Util.stringAppendList({prefix_str,"_init.txt"});
      then
        (cache,init_filename,starttime_r,stoptime_r,interval_r,tolerance_r,method_str,options_str);
    case (_,_,_,_,_,_)
      equation 
        Print.printErrorBuf("#- Ceval.calculateSimulationSettings failed\n");
      then
        fail();
  end matchcontinue;
end calculateSimulationSettings;

public function buildModel "function buildModel
 author: x02lucpo
 translates and builds the model by running compiler script on the generated makefile"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output String outString1 "className";
  output String outString2 "method";
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable3;
  output String outString4 "initFileName";
algorithm 
  (outCache,outString1,outString2,outInteractiveSymbolTable3,outString4):=
  matchcontinue (inCache,inEnv,inExp,inInteractiveSymbolTable,inMsg)
    local
      Values.Value ret_val;
      Interactive.InteractiveSymbolTable st,st_1,st2;
      DAELow.DAELow indexed_dlow_1;
      list<String> libs;
      String prefix_str,file_dir,cname_str,init_filename,method_str,filenameprefix,makefilename,oldDir,tempDir,tolerance_str,options_str;
      Absyn.Path classname,w;
      Absyn.Program p,p2;
      Absyn.Class cdef;
      list<Interactive.CompiledCFunction> cf;
      Real starttime_r,stoptime_r,interval_r,tolerance_r;
      list<Env.Frame> env;
      Exp.Exp exp,starttime,stoptime,interval,tolerance,method,fileprefix,storeInTemp,noClean,options;
      Exp.ComponentRef cr;      
      list<SCode.Class> sp;
      AbsynDep.Depends aDep;
      list<Interactive.InstantiatedClass> ic;
      list<Interactive.InteractiveVariable> iv;      
      Ceval.Msg msg;
      Absyn.Within win1;
      Env.Cache cache;
      Boolean cdToTemp;
    case (cache,env,(exp as Exp.CALL(path = Absyn.IDENT(name = _),
          expLst = {Exp.CODE(Absyn.C_TYPENAME(classname),_),starttime,stoptime,interval,tolerance,method,fileprefix,storeInTemp,_,options})),
          (st_1 as Interactive.SYMBOLTABLE(ast = p as Absyn.PROGRAM(globalBuildTimes=Absyn.TIMESTAMP(_,edit)),explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      // If we already have an up-to-date version of the binary file, we don't need to recompile. 
      local String exeFile;
        Real edit,build; Integer existFile;
        String s1,s2;
      equation 
        //cdef = Interactive.getPathedClassInProgram(classname,p);
        _ = Error.getMessagesStr() "Clear messages";
        // Only compile if change occured after last build.
        ( Absyn.CLASS(info = Absyn.INFO(buildTimes= Absyn.TIMESTAMP(build,_)))) = Interactive.getPathedClassInProgram(classname,p);
        true = (build >. edit);
        (cache,Values.BOOL(cdToTemp),SOME(st)) = Ceval.ceval(cache,env, storeInTemp, true, SOME(st_1), NONE, msg);
        oldDir = System.pwd();
        changeToTempDirectory(cdToTemp);
        (cache,filenameprefix) = extractFilePrefix(cache,env, fileprefix, st_1, msg);
        (cache,Values.STRING(prefix_str),SOME(st2)) = Ceval.ceval(cache,env, fileprefix, true, SOME(st_1), NONE, msg);
        init_filename = Util.stringAppendList({prefix_str,"_init.txt"});
        (cache,Values.STRING(method_str),SOME(st2)) = Ceval.ceval(cache,env, method, true, SOME(st2), NONE, msg);
        exeFile = Util.stringAppendList({filenameprefix, ".exe"});
        existFile = System.regularFileExists(exeFile);
        _ = System.cd(oldDir);
        true = existFile == 0; 
    then
      (cache,filenameprefix,method_str,st2,init_filename);

    case (cache,env,(exp as Exp.CALL(path = Absyn.IDENT(name = _),expLst = ({Exp.CODE(Absyn.C_TYPENAME(classname),_),starttime,stoptime,interval,tolerance,method,fileprefix,storeInTemp,noClean,options}))),(st_1 as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local Absyn.TimeStamp ts,ts2;
        Real r1,r2,globalEdit,globalBuild;
        String s1,s2,s3;
        
      equation 
        (cdef as Absyn.CLASS(info = Absyn.INFO(buildTimes=ts as Absyn.TIMESTAMP(_,globalEdit)))) = Interactive.getPathedClassInProgram(classname,p);
        Absyn.PROGRAM(_,_,Absyn.TIMESTAMP(globalBuild,_)) = p;
           
        _ = Error.getMessagesStr() "Clear messages";
        (cache,Values.BOOL(cdToTemp),SOME(st)) = Ceval.ceval(cache,env, storeInTemp, true, SOME(st_1), NONE, msg);
        oldDir = System.pwd();
        changeToTempDirectory(cdToTemp);
        (cache,ret_val,st,indexed_dlow_1,libs,file_dir) = translateModel(cache,env, classname, st_1, msg, fileprefix,true);
        cname_str = Absyn.pathString(classname);
        (cache,init_filename,starttime_r,stoptime_r,interval_r,tolerance_r,method_str,options_str) = calculateSimulationSettings(cache,env, exp, st, msg, cname_str);
        (cache,filenameprefix) = extractFilePrefix(cache,env, fileprefix, st, msg);
        SimCodegen.generateInitData(indexed_dlow_1, classname, filenameprefix, init_filename, 
          starttime_r, stoptime_r, interval_r, tolerance_r, method_str,options_str);
        win1 = getWithinStatement(classname);       
        s3 = extractNoCleanCommand(noClean);
        makefilename = generateMakefilename(filenameprefix);
        Debug.fprintln("dynload", "buildModel: about to compile model " +& filenameprefix +& ", " +& file_dir);
        compileModel(filenameprefix, libs, file_dir, s3); 
        Debug.fprintln("dynload", "buildModel: Compiling done.");
        _ = System.cd(oldDir);
        p = setBuildTime(p,classname);
        st2 = st;// Interactive.replaceSymbolTableProgram(st,p); 
      then
        (cache,filenameprefix,method_str,st2,init_filename);
    case (_,_,_,_,_)
      then
        fail();
  end matchcontinue;
end buildModel;

protected function changeToTempDirectory "function changeToTempDirectory
changes to temp directory (set using the functions from Settings.mo) 
if the boolean flag given as input is true"
	input Boolean cdToTemp;
algorithm
  _ := matchcontinue(cdToTemp) 
  local String tempDir;
    case(true) equation
   			tempDir = Settings.getTempDirectoryPath();
        0 = System.cd(tempDir);
        then ();
    case(_) then ();
  end matchcontinue;
end changeToTempDirectory;

public function getFileDir "function: getFileDir
  author: x02lucpo
  returns the dir where class file (.mo) was saved or 
  $OPENMODELICAHOME/work if the file was not saved yet"
  input Absyn.ComponentRef inComponentRef "class";
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path p_class;
      Absyn.Class cdef;
      String filename,pd,dir_1,omhome,omhome_1,cit;
      String pd_1;
      list<String> filename_1,dir;
      Absyn.ComponentRef class_;
      Absyn.Program p;
    case (class_,p)
      equation 
        p_class = Absyn.crefToPath(class_) "change to the saved files directory" ;
        cdef = Interactive.getPathedClassInProgram(p_class, p);
        filename = Absyn.classFilename(cdef);
        pd = System.pathDelimiter();
        (pd_1 :: _) = string_list_string_char(pd);
        filename_1 = Util.stringSplitAtChar(filename, pd_1);
        dir = Util.listStripLast(filename_1);
        dir_1 = Util.stringDelimitList(dir, pd);
      then
        dir_1;
    case (class_,p)
      equation 
        omhome = Settings.getInstallationDirectoryPath() "model not yet saved! change to $OPENMODELICAHOME/work" ;
        omhome_1 = System.trim(omhome, "\"");
        pd = System.pathDelimiter();
        cit = winCitation();
        dir_1 = Util.stringAppendList({cit,omhome_1,pd,"work",cit});
      then
        dir_1;
    case (_,_) then "";  /* this function should never fail */ 
  end matchcontinue;
end getFileDir;

protected function compileModel "function: compileModel
  author: PA, x02lucpo
  Compiles a model given a file-prefix, helper function to buildModel."
  input String inFilePrefix;
  input list<String> inLibsList;
  input String inFileDir;
  input String noClean;
algorithm 
  _:= matchcontinue (inFilePrefix,inLibsList,inFileDir,noClean)
    local
      String pd,omhome,omhome_1,cd_path,libsfilename,libs_str,s_call,fileprefix,file_dir,command,filename,str;
      list<String> libs;
      
      // If compileCommand not set, use $OPENMODELICAHOME\bin\Compile
    case (fileprefix,libs,file_dir,noClean) 
      equation 
        "" = Settings.getCompileCommand();
        pd = System.pathDelimiter();
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.stringReplace(omhome, "\"", "");
        cd_path = System.pwd();
        libsfilename = stringAppend(fileprefix, ".libs");
        libs_str = Util.stringDelimitList(libs, " ");
        System.writeFile(libsfilename, libs_str);
        s_call = 
        Util.stringAppendList({"set OPENMODELICAHOME=",omhome_1,"&& ",
          omhome_1,pd,"bin",pd,"Compile"," ",fileprefix," ",noClean});
        Debug.fprintln("dynload", "compileModel: running " +& s_call);
        0 = System.systemCall(s_call)  ;
        Debug.fprintln("dynload", "compileModel: successful! ");        
      then
        ();
        // If compileCommand is set.
    case (fileprefix,libs,file_dir,noClean)
      equation 
        command = Settings.getCompileCommand();
        false = Util.isEmptyString(command);
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.stringReplace(omhome, "\"", "");
        cd_path = System.pwd() "needed when the above rule does not work" ;
        libs_str = Util.stringDelimitList(libs, " ");
        libsfilename = stringAppend(fileprefix, ".libs");
        System.writeFile(libsfilename, libs_str);
        s_call = Util.stringAppendList({"set OPENMODELICAHOME=",omhome_1,"&& ",command," ",fileprefix," ",noClean});
        // print(s_call);
        Debug.fprintln("dynload", "compileModel: running " +& s_call);
        0 = System.systemCall(s_call) ;
        Debug.fprintln("dynload", "compileModel: successful! ");        
      then
        ();     
        
    case (fileprefix,libs,file_dir,_) /* compilation failed */ 
      equation 
        filename = Util.stringAppendList({fileprefix,".log"});
        0 = System.regularFileExists(filename);
        str = System.readFile(filename);
        Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {str});
        Debug.fprintln("dynload", "compileModel: failed!");        
      then
        fail();
    case (fileprefix,libs,file_dir,_)
      local Integer retVal;
      equation 
        command = Settings.getCompileCommand();
        false = Util.isEmptyString(command);
        retVal = System.regularFileExists(command);
        true = retVal <> 0; 
        str=Util.stringAppendList({"command ",command," not found. Check $OPENMODELICAHOME"});
        Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {str});
      then fail();
        
    case (fileprefix,libs,file_dir,_) /* compilation failed\\n */ 
      local Integer retVal;
      equation  
        omhome = Settings.getInstallationDirectoryPath();
        omhome_1 = System.stringReplace(omhome, "\"", "");
        pd = System.pathDelimiter();
        /* adrpo - 2006-08-28 -> 
         * please leave Compile instead of Compile.bat 
         * here as it has to work on Linux too
         */
        s_call = Util.stringAppendList({"\"",omhome_1,pd,"bin",pd,"Compile","\""});
        retVal = System.regularFileExists(s_call);
        true = retVal <> 0; 
        str=Util.stringAppendList({"command ",s_call," not found. Check $OPENMODELICAHOME"});
        Error.addMessage(Error.SIMULATOR_BUILD_ERROR, {str});
      then
        fail();
    case (fileprefix,libs,file_dir,_)
      equation 
        Print.printErrorBuf("#- Error building simulation code. Ceval.compileModel failed.\n ");
      then
        fail();
  end matchcontinue;
end compileModel;

protected function winCitation "function: winCitation
  author: PA
  Returns a citation mark if platform is windows, otherwise empty string. 
  Used by simulate to make whitespaces work in filepaths for WIN32"
  output String outString;
algorithm 
  outString:=
  matchcontinue ()
    case ()
      equation 
        "WIN32" = System.platform();
      then
        "\"";
    case () then ""; 
  end matchcontinue;
end winCitation;

protected function extractFilePrefix "function extractFilePrefix
  author: x02lucpo 
  extracts the file prefix from Exp.Exp as string"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output String outString;
algorithm 
  (outCache,outString):=
  matchcontinue (inCache,inEnv,inExp,inInteractiveSymbolTable,inMsg)
    local
      String prefix_str;
      Interactive.InteractiveSymbolTable st;
      list<Env.Frame> env;
      Exp.Exp filenameprefix;
      Absyn.Program p;
      list<SCode.Class> sp;
      list<Interactive.InstantiatedClass> ic;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      Env.Cache cache;
    case (cache,env,filenameprefix,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        (cache,Values.STRING(prefix_str),SOME(st)) = Ceval.ceval(cache,env, filenameprefix, true, SOME(st), NONE, msg);
      then
        (cache,prefix_str);
    case (_,_,_,_,_) then fail(); 
  end matchcontinue;
end extractFilePrefix;

public function cevalAstExp 
"function: cevalAstExp
  Part of meta-programming using CODE.
  This function evaluates a piece of Expression AST, replacing Eval(variable)
  with the value of the variable, given that it is of type \"Expression\".
  
  Example: y = Code(1 + x)
           2 + 5  ( x + Eval(y) )  =>   2 + 5  ( x + 1 + x )"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Exp inExp;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Absyn.Exp outExp;
algorithm 
  (outCache,outExp) :=
  matchcontinue (inCache,inEnv,inExp,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Absyn.Exp e,e1_1,e2_1,e1,e2,e_1,cond_1,then_1,else_1,cond,then_,else_,exp,e3_1,e3;
      list<Env.Frame> env;
      Absyn.Operator op;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Ceval.Msg msg;
      list<tuple<Absyn.Exp, Absyn.Exp>> nest_1,nest;
      Absyn.ComponentRef cr;
      Absyn.FunctionArgs fa;
      list<Absyn.Exp> expl_1,expl;
      Env.Cache cache;
    case (cache,_,(e as Absyn.INTEGER(value = _)),_,_,_) then (cache,e); 
    case (cache,_,(e as Absyn.REAL(value = _)),_,_,_) then (cache,e); 
    case (cache,_,(e as Absyn.CREF(componentReg = _)),_,_,_) then (cache,e); 
    case (cache,_,(e as Absyn.STRING(value = _)),_,_,_) then (cache,e); 
    case (cache,_,(e as Absyn.BOOL(value = _)),_,_,_) then (cache,e); 
    case (cache,env,Absyn.BINARY(exp1 = e1,op = op,exp2 = e2),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg);
      then
        (cache,Absyn.BINARY(e1_1,op,e2_1));
    case (cache,env,Absyn.UNARY(op = op,exp = e),impl,st,msg)
      equation 
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg);
      then
        (cache,Absyn.UNARY(op,e_1));
    case (cache,env,Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg);
      then
        (cache,Absyn.LBINARY(e1_1,op,e2_1));
    case (cache,env,Absyn.LUNARY(op = op,exp = e),impl,st,msg)
      equation 
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg);
      then
        (cache,Absyn.LUNARY(op,e_1));
    case (cache,env,Absyn.RELATION(exp1 = e1,op = op,exp2 = e2),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg);
      then
        (cache,Absyn.RELATION(e1_1,op,e2_1));
    case (cache,env,Absyn.IFEXP(ifExp = cond,trueBranch = then_,elseBranch = else_,elseIfBranch = nest),impl,st,msg)
      equation 
        (cache,cond_1) = cevalAstExp(cache,env, cond, impl, st, msg);
        (cache,then_1) = cevalAstExp(cache,env, then_, impl, st, msg);
        (cache,else_1) = cevalAstExp(cache,env, else_, impl, st, msg);
        (cache,nest_1) = cevalAstExpexpList(cache,env, nest, impl, st, msg);
      then
        (cache,Absyn.IFEXP(cond_1,then_1,else_1,nest_1));
    case (cache,env,Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "Eval",subscripts = {}),functionArgs = Absyn.FUNCTIONARGS(args = {e},argNames = {})),impl,st,msg)
      local Exp.Exp e_1;
      equation 
        (cache,e_1,_,_) = Static.elabExp(cache,env, e, impl, st,true);
        (cache,Values.CODE(Absyn.C_EXPRESSION(exp)),_) = Ceval.ceval(cache,env, e_1, impl, st, NONE, msg);
      then
        (cache,exp);
    case (cache,env,(e as Absyn.CALL(function_ = cr,functionArgs = fa)),_,_,msg) then (cache,e); 
    case (cache,env,Absyn.ARRAY(arrayExp = expl),impl,st,msg)
      equation 
        (cache,expl_1) = cevalAstExpList(cache,env, expl, impl, st, msg);
      then
        (cache,Absyn.ARRAY(expl_1));
    case (cache,env,Absyn.MATRIX(matrix = expl),impl,st,msg)
      local list<list<Absyn.Exp>> expl_1,expl;
      equation 
        (cache,expl_1) = cevalAstExpListList(cache,env, expl, impl, st, msg);
      then
        (cache,Absyn.MATRIX(expl_1));
    case (cache,env,Absyn.RANGE(start = e1,step = SOME(e2),stop = e3),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg);
        (cache,e3_1) = cevalAstExp(cache,env, e3, impl, st, msg);
      then
        (cache,Absyn.RANGE(e1_1,SOME(e2_1),e3_1));
    case (cache,env,Absyn.RANGE(start = e1,step = NONE,stop = e3),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e3_1) = cevalAstExp(cache,env, e3, impl, st, msg);
      then
        (cache,Absyn.RANGE(e1_1,NONE,e3_1));
    case (cache,env,Absyn.TUPLE(expressions = expl),impl,st,msg)
      equation 
        (cache,expl_1) = cevalAstExpList(cache,env, expl, impl, st, msg);
      then
        (cache,Absyn.TUPLE(expl_1));
    case (cache,env,Absyn.END(),_,_,msg) then (cache,Absyn.END()); 
    case (cache,env,(e as Absyn.CODE(code = _)),_,_,msg) then (cache,e); 
  end matchcontinue;
end cevalAstExp;

public function cevalAstExpList 
"function: cevalAstExpList
  List version of cevalAstExp"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.Exp> inAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output list<Absyn.Exp> outAbsynExpLst;
algorithm 
  (outCache,outAbsynExpLst) :=
  matchcontinue (inCache,inEnv,inAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Ceval.Msg msg;
      Absyn.Exp e_1,e;
      list<Absyn.Exp> res,es;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
    case (cache,env,{},_,_,msg) then (cache,{}); 
    case (cache,env,(e :: es),impl,st,msg)
      equation 
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg);
        (cache,res) = cevalAstExpList(cache,env, es, impl, st, msg);
      then
        (cache,e :: res);
  end matchcontinue;
end cevalAstExpList;

protected function cevalAstExpListList "function: cevalAstExpListList"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<list<Absyn.Exp>> inAbsynExpLstLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output list<list<Absyn.Exp>> outAbsynExpLstLst;
algorithm 
  (outCache,outAbsynExpLstLst) :=
  matchcontinue (inCache,inEnv,inAbsynExpLstLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Ceval.Msg msg;
      list<Absyn.Exp> e_1,e;
      list<list<Absyn.Exp>> res,es;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
    case (cache,env,{},_,_,msg) then (cache,{}); 
    case (cache,env,(e :: es),impl,st,msg)
      equation 
        (cache,e_1) = cevalAstExpList(cache,env, e, impl, st, msg);
        (cache,res) = cevalAstExpListList(cache,env, es, impl, st, msg);
      then
        (cache,e :: res);
  end matchcontinue;
end cevalAstExpListList;

protected function cevalAstExpexpList 
"function: cevalAstExpexpList
  For IFEXP"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<tuple<Absyn.Exp, Absyn.Exp>> inTplAbsynExpAbsynExpLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output list<tuple<Absyn.Exp, Absyn.Exp>> outTplAbsynExpAbsynExpLst;
algorithm 
  (outCache,outTplAbsynExpAbsynExpLst) :=
  matchcontinue (inCache,inEnv,inTplAbsynExpAbsynExpLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Ceval.Msg msg;
      Absyn.Exp e1_1,e2_1,e1,e2;
      list<tuple<Absyn.Exp, Absyn.Exp>> res,xs;
      list<Env.Frame> env;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Env.Cache cache;
    case (cache,_,{},_,_,msg) then (cache,{}); 
    case (cache,env,((e1,e2) :: xs),impl,st,msg)
      equation 
        (cache,e1_1) = cevalAstExp(cache,env, e1, impl, st, msg);
        (cache,e2_1) = cevalAstExp(cache,env, e2, impl, st, msg);
        (cache,res) = cevalAstExpexpList(cache,env, xs, impl, st, msg);
      then
        (cache,(e1_1,e2_1) :: res);
  end matchcontinue;
end cevalAstExpexpList;

public function cevalAstElt 
"function: cevalAstElt
  Evaluates an ast constructor for Element nodes, e.g. 
  Code(parameter Real x=1;)"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Element inElement;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Absyn.Element outElement;
algorithm 
  (outCache,outElement) :=
  matchcontinue (inCache,inEnv,inElement,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Absyn.ComponentItem> citems_1,citems;
      list<Env.Frame> env;
      Boolean f,isReadOnly,impl;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter io;
      String id,file;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec tp;
      Absyn.Info info;
      Integer sline,scolumn,eline,ecolumn;
      Option<Absyn.ConstrainClass> c;
      Option<Interactive.InteractiveSymbolTable> st;
      Ceval.Msg msg;
      Env.Cache cache;
    case (cache,env,Absyn.ELEMENT(finalPrefix = f,redeclareKeywords = r,innerOuter = io,name = id,specification = Absyn.COMPONENTS(attributes = attr,typeSpec = tp,components = citems),info = (info as Absyn.INFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scolumn,lineNumberEnd = eline,columnNumberEnd = ecolumn)),constrainClass = c),impl,st,msg)
      equation 
        (cache,citems_1) = cevalAstCitems(cache,env, citems, impl, st, msg);
      then
        (cache,Absyn.ELEMENT(f,r,io,id,Absyn.COMPONENTS(attr,tp,citems_1),info,c));
  end matchcontinue;
end cevalAstElt;

protected function cevalAstCitems 
"function: cevalAstCitems
  Helper function to cevalAstElt."
 	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm 
  (outCache,outAbsynComponentItemLst) :=
  matchcontinue (inCache,inEnv,inAbsynComponentItemLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Ceval.Msg msg;
      list<Absyn.ComponentItem> res,xs;
      Option<Absyn.Modification> modopt_1,modopt;
      list<Absyn.Subscript> ad_1,ad;
      list<Env.Frame> env;
      String id;
      Option<Absyn.Exp> cond;
      Option<Absyn.Comment> cmt;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Absyn.ComponentItem x;
      Env.Cache cache;
    case (cache,_,{},_,_,msg) then (cache,{}); 
    case (cache,env,(Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = ad,modification = modopt),condition = cond,comment = cmt) :: xs),impl,st,msg) /* If one component fails, the rest should still succeed */ 
      equation 
        (cache,res) = cevalAstCitems(cache,env, xs, impl, st, msg);
        (cache,modopt_1) = cevalAstModopt(cache,env, modopt, impl, st, msg);
        (cache,ad_1) = cevalAstArraydim(cache,env, ad, impl, st, msg);
      then
        (cache,Absyn.COMPONENTITEM(Absyn.COMPONENT(id,ad_1,modopt_1),cond,cmt) :: res);
    case (cache,env,(x :: xs),impl,st,msg) /* If one component fails, the rest should still succeed */ 
      equation 
        (cache,res) = cevalAstCitems(cache,env, xs, impl, st, msg);
      then
        (cache,x :: res);
  end matchcontinue;
end cevalAstCitems;

protected function cevalAstModopt 
"function: cevalAstModopt"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Option<Absyn.Modification> inAbsynModificationOption;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Option<Absyn.Modification> outAbsynModificationOption;
algorithm 
  (outCache,outAbsynModificationOption) :=
  matchcontinue (inCache,inEnv,inAbsynModificationOption,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Absyn.Modification res,mod;
      list<Env.Frame> env;
      Boolean st;
      Option<Interactive.InteractiveSymbolTable> impl;
      Ceval.Msg msg;
      Env.Cache cache;
    case (cache,env,SOME(mod),st,impl,msg)
      equation 
        (cache,res) = cevalAstModification(cache,env, mod, st, impl, msg);
      then
        (cache,SOME(res));
    case (cache,env,NONE,_,_,msg) then (cache,NONE); 
  end matchcontinue;
end cevalAstModopt;

protected function cevalAstModification "function: cevalAstModification
  This function evaluates Eval(variable) inside an AST Modification  and replaces 
  the Eval operator with the value of the variable if it has a type \"Expression\""
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Modification inModification;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Absyn.Modification outModification;
algorithm 
  (outCache,outModification) :=
  matchcontinue (inCache,inEnv,inModification,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      Absyn.Exp e_1,e;
      list<Absyn.ElementArg> eltargs_1,eltargs;
      list<Env.Frame> env;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Ceval.Msg msg;
      Env.Cache cache;
    case (cache,env,Absyn.CLASSMOD(elementArgLst = eltargs,expOption = SOME(e)),impl,st,msg)
      equation 
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg);
        (cache,eltargs_1) = cevalAstEltargs(cache,env, eltargs, impl, st, msg);
      then
        (cache,Absyn.CLASSMOD(eltargs_1,SOME(e_1)));
    case (cache,env,Absyn.CLASSMOD(elementArgLst = eltargs,expOption = NONE),impl,st,msg)
      equation 
        (cache,eltargs_1) = cevalAstEltargs(cache,env, eltargs, impl, st, msg);
      then
        (cache,Absyn.CLASSMOD(eltargs_1,NONE));
  end matchcontinue;
end cevalAstModification;

protected function cevalAstEltargs "function: cevalAstEltargs
  Helper function to cevalAstModification."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm 
  (outCache,outAbsynElementArgLst):=
  matchcontinue (inCache,inEnv,inAbsynElementArgLst,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Ceval.Msg msg;
      Absyn.Modification mod_1,mod;
      list<Absyn.ElementArg> res,args;
      Boolean b,impl;
      Absyn.Each e;
      Absyn.ComponentRef cr;
      Option<String> stropt;
      Option<Interactive.InteractiveSymbolTable> st;
      Absyn.ElementArg m;
      Env.Cache cache;
    case (cache,env,{},_,_,msg) then (cache,{}); 
    /* TODO: look through redeclarations for Eval(var) as well */   
    case (cache,env,(Absyn.MODIFICATION(finalItem = b,each_ = e,componentReg = cr,modification = SOME(mod),comment = stropt) :: args),impl,st,msg) 
      equation 
        (cache,mod_1) = cevalAstModification(cache,env, mod, impl, st, msg);
        (cache,res) = cevalAstEltargs(cache,env, args, impl, st, msg);
      then
        (cache,Absyn.MODIFICATION(b,e,cr,SOME(mod_1),stropt) :: res);
    case (cache,env,(m :: args),impl,st,msg) /* TODO: look through redeclarations for Eval(var) as well */ 
      equation 
        (cache,res) = cevalAstEltargs(cache,env, args, impl, st, msg);
      then
        (cache,m :: res);
  end matchcontinue;
end cevalAstEltargs;

protected function cevalAstArraydim "function: cevalAstArraydim
  Helper function to cevaAstCitems"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.ArrayDim inArrayDim;
  input Boolean inBoolean;
  input Option<Interactive.InteractiveSymbolTable> inInteractiveInteractiveSymbolTableOption;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Absyn.ArrayDim outArrayDim;
algorithm 
  (outCache,outArrayDim) :=
  matchcontinue (inCache,inEnv,inArrayDim,inBoolean,inInteractiveInteractiveSymbolTableOption,inMsg)
    local
      list<Env.Frame> env;
      Ceval.Msg msg;
      list<Absyn.Subscript> res,xs;
      Boolean impl;
      Option<Interactive.InteractiveSymbolTable> st;
      Absyn.Exp e_1,e;
      Env.Cache cache;
    case (cache,env,{},_,_,msg) then (cache,{}); 
    case (cache,env,(Absyn.NOSUB() :: xs),impl,st,msg)
      equation 
        (cache,res) = cevalAstArraydim(cache,env, xs, impl, st, msg);
      then
        (cache,Absyn.NOSUB() :: res);
    case (cache,env,(Absyn.SUBSCRIPT(subScript = e) :: xs),impl,st,msg)
      equation 
        (cache,res) = cevalAstArraydim(cache,env, xs, impl, st, msg);
        (cache,e_1) = cevalAstExp(cache,env, e, impl, st, msg);
      then
        (cache,Absyn.SUBSCRIPT(e) :: res);
  end matchcontinue;
end cevalAstArraydim;

public function checkModel "function: checkModel
 checks a model and returns number of variables and equations"
	input Env.Cache inCache;
	input Env.Env inEnv;
  input Absyn.Path className;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outCache,outValue,outInteractiveSymbolTable) := 
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg)
    local
      String filenameprefix,cname_str,filename,funcfilename,makefilename,file_dir;
      Absyn.Path classname;
      list<SCode.Class> p_1,sp;
      DAE.DAElist dae_1,dae;
      list<Env.Frame> env;
      list<DAE.Element> dael;
      list<Interactive.InstantiatedClass> ic_1,ic;
      DAELow.DAELow dlow,dlow_1,indexed_dlow,indexed_dlow_1;
      list<Integer>[:] m,mT;
      Integer[:] ass1,ass2;
      list<list<Integer>> comps;
      Absyn.ComponentRef a_cref;
      list<String> libs;
      Exp.ComponentRef cr;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p,ptot;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      Exp.Exp fileprefix;
      Env.Cache cache;
      Integer eqnSize,varSize,simpleEqnSize;
      String warnings,eqnSizeStr,varSizeStr,retStr,classNameStr,simpleEqnSizeStr;
      DAELow.EquationArray eqns;
      Integer elimLevel; 

    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)  
      equation
        ptot = Interactive.getTotalProgram(className,p);
        // this case should not handle functions
        failure(Absyn.CLASS(_,_,_,_,Absyn.R_FUNCTION(),_,_) = Interactive.getPathedClassInProgram(className, p)); 
        _ = Error.getMessagesStr() "Clear messages";
        Print.clearErrorBuf() "Clear error buffer";
        p_1 = SCode.elaborate(ptot); 
        
        //UnitParserExt.clear();
        //UnitAbsynBuilder.registerUnits(ptot);
        //UnitParserExt.commit();
        
        (cache, env, _, dae as DAE.DAE(dael)) = 
        Inst.instantiateClass(inCache, InstanceHierarchy.emptyInstanceHierarchy, p_1, className);        
        ((dae as DAE.DAE(dael))) = DAE.transformIfEqToExpr(dae);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dael,env));
        elimLevel = RTOpts.eliminationLevel();
        RTOpts.setEliminationLevel(0); // No variable elimination
        (dlow as DAELow.DAELOW(orderedVars = DAELow.VARIABLES(numberOfVars = varSize),orderedEqs = eqns)) 
        = DAELow.lower(dae, false/* no dummy variable*/, true);
        RTOpts.setEliminationLevel(elimLevel); // reset elimination level.
        eqnSize = DAELow.equationSize(eqns);
        (eqnSize,varSize) = subtractDummy(DAELow.daeVars(dlow),eqnSize,varSize);
        simpleEqnSize = DAELow.countSimpleEquations(eqns);
        eqnSizeStr = intString(eqnSize);
        varSizeStr = intString(varSize);
        simpleEqnSizeStr = intString(simpleEqnSize);
        
        classNameStr = Absyn.pathString(className);
        warnings = Error.printMessagesStr();
        retStr=Util.stringAppendList({"Check of ",classNameStr," completed successfully.\n\n",warnings,"\nClass ",classNameStr," has ",eqnSizeStr," equation(s) and ",
          varSizeStr," variable(s).\n",simpleEqnSizeStr," of these are trivial equation(s).\n"});
      then
        (cache,Values.STRING(retStr),st);

    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)  
      equation 
        ptot = Interactive.getTotalProgram(className,p);
        //(cache,dae as DAE.DAE(dael),env) = checkModelInstantiateCall(cache,ptot, className);        
        Absyn.CLASS(_,_,_,_,Absyn.R_FUNCTION(),_,_) = Interactive.getPathedClassInProgram(className, p);
        _ = Error.getMessagesStr() "Clear messages";
        Print.clearErrorBuf() "Clear error buffer";        
        p_1 = SCode.elaborate(ptot);
        
        //UnitParserExt.clear();
        //UnitAbsynBuilder.registerUnits(ptot);
        //UnitParserExt.commit();

        (cache, env, _, dae as DAE.DAE(dael)) = 
        Inst.instantiateFunctionImplicit(inCache, InstanceHierarchy.emptyInstanceHierarchy, p_1, className);
      
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dael,env));
				classNameStr = Absyn.pathString(className);
				warnings = Error.printMessagesStr();
				// TODO: add a check if warnings is empty, if so then remove \n... --> warnings,"\nClass  <--- line below.
				retStr=Util.stringAppendList({"Check of ",classNameStr," completed successfully.\n\n",warnings,"\n"});
      then
        (cache,Values.STRING(retStr),st);

    case (cache,env,className,st,_) local
      String errorMsg; Boolean strEmpty; String errorBuffer;
      equation
      classNameStr = Absyn.pathString(className);
      errorMsg = Error.printMessagesStr();
      strEmpty = (System.strcmp("",errorMsg)==0);
      errorMsg = Util.if_(strEmpty,"Internal error, check of model failed with no error message.",errorMsg);
      // errorMsg = errorMsg +& selectIfNotEmpty("Error Buffer:\n", Print.getErrorString());
    then (cache,Values.STRING(errorMsg),st);  

  end matchcontinue;
end checkModel; 

protected function selectIfNotEmpty
  input String inString;
  input String selector " "; 
  output String outString;
algorithm
  outString := matchcontinue(inString, selector)
    case (_, "") then "";
    case (inString, selector)
      local String s; 
      equation
        s = inString +& selector;
      then s;
  end matchcontinue;
end selectIfNotEmpty;

protected function getBuiltinAttribute "function: getBuiltinAttribute
  Retrieves a builtin attribute of a variable in a class by instantiating 
  the class and retrieving the attribute value from the flat variable."	
	input Env.Cache inCache;
  input Exp.ComponentRef inComponentRef1;
  input Exp.ComponentRef inComponentRef2;
  input String inString3;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable4;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outCache,outValue,outInteractiveSymbolTable):=
  matchcontinue (inCache,inComponentRef1,inComponentRef2,inString3,inInteractiveSymbolTable4)
    local
      Absyn.Path classname_1;
      list<DAE.Element> dae,dae1;
      list<Env.Frame> env,env_1,env3,env4;
      Exp.ComponentRef cref_1,classname,cref;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Exp.Exp exp;
      String str,n,attribute;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p,ptot;
      list<SCode.Class> sp,p_1;
      list<Interactive.InstantiatedClass> ic,ic_1;
      list<Interactive.InteractiveVariable> vars;
      list<Interactive.CompiledCFunction> cf;
      SCode.Class c;
      Boolean encflag;
      SCode.Restriction r;
      ClassInf.State ci_state,ci_state_1;
      Connect.Sets csets_1;
      list<Types.Var> tys;
      Values.Value v;
      Env.Cache cache;
      list<Interactive.LoadedFile> lf;
      AbsynDep.Depends aDep;
    case (cache,classname,cref,"stateSelect",
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = vars,
        compiledFunctions = cf)))
      equation 
        classname_1 = Static.componentRefToPath(classname) "Check cached instantiated class" ;
        Interactive.INSTCLASS(_,dae,env) = Interactive.getInstantiatedClass(ic, classname_1);
        cref_1 = Exp.joinCrefs(cref, Exp.CREF_IDENT("stateSelect",Exp.OTHER(),{}));
        (cache,attr,ty,Types.EQBOUND(exp,_,_),_,_) = Lookup.lookupVar(cache,env, cref_1); 
        str = Exp.printExpStr(exp);
      then
        (cache,Values.STRING(str),st);
        
    case (cache,classname,cref,"stateSelect",
      Interactive.SYMBOLTABLE(
        ast = p,
        depends = aDep,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = vars,
        compiledFunctions = cf,
        loadedFiles = lf))
      equation 
        classname_1 = Static.componentRefToPath(classname);
        ptot = Interactive.getTotalProgram(classname_1,p);          
        p_1 = SCode.elaborate(ptot);
        (cache,env) = Inst.makeEnvFromProgram(cache,p_1, Absyn.IDENT(""));
        (cache,(c as SCode.CLASS(n,_,encflag,r,_)),env_1) = Lookup.lookupClass(cache,env, classname_1, true);
        env3 = Env.openScope(env_1, encflag, SOME(n));
        ci_state = ClassInf.start(r, n);
        (cache,env4,_,_,dae1,csets_1,ci_state_1,tys,_,_,_,_) = Inst.instClassIn(cache,env3, InstanceHierarchy.emptyInstanceHierarchy,UnitAbsyn.noStore,Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, false, ConnectionGraph.EMPTY,NONE);
        cref_1 = Exp.joinCrefs(cref, Exp.CREF_IDENT("stateSelect",Exp.OTHER(),{}));
        (cache,attr,ty,Types.EQBOUND(exp,_,_),_,_) = Lookup.lookupVar(cache,env4, cref_1);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(classname_1,dae1,env4));
        str = Exp.printExpStr(exp);
      then
        (cache,Values.STRING(str),Interactive.SYMBOLTABLE(p,aDep,sp,ic_1,vars,cf,lf));
        
    case (cache,classname,cref,attribute,
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = vars,
        compiledFunctions = cf)))
      equation 
        classname_1 = Static.componentRefToPath(classname);
        Interactive.INSTCLASS(_,dae,env) = Interactive.getInstantiatedClass(ic, classname_1);
        cref_1 = Exp.joinCrefs(cref, Exp.CREF_IDENT(attribute,Exp.OTHER(),{}));
        (cache,attr,ty,Types.VALBOUND(v),_,_) = Lookup.lookupVar(cache,env, cref_1);
      then
        (cache,v,st);
        
    case (cache,classname,cref,attribute,
      (st as Interactive.SYMBOLTABLE(
        ast = p,
        depends = aDep,
        explodedAst = sp,
        instClsLst = ic,
        lstVarVal = vars,
        compiledFunctions = cf,
        loadedFiles = lf)))
      equation 
        classname_1 = Static.componentRefToPath(classname);
        ptot = Interactive.getTotalProgram(classname_1,p);          
        p_1 = SCode.elaborate(ptot);
        (cache,env) = Inst.makeEnvFromProgram(cache,p_1, Absyn.IDENT(""));
        (cache,(c as SCode.CLASS(n,_,encflag,r,_)),env_1) = Lookup.lookupClass(cache,env, classname_1, true);
        env3 = Env.openScope(env_1, encflag, SOME(n));
        ci_state = ClassInf.start(r, n);
        (cache,env4,_,_,dae1,csets_1,ci_state_1,tys,_,_,_,_) = Inst.instClassIn(cache,env3, InstanceHierarchy.emptyInstanceHierarchy, UnitAbsyn.noStore,Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {}, false, ConnectionGraph.EMPTY,NONE);
        cref_1 = Exp.joinCrefs(cref, Exp.CREF_IDENT(attribute,Exp.OTHER(),{}));
        (cache,attr,ty,Types.VALBOUND(v),_,_) = Lookup.lookupVar(cache,env4, cref_1);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(classname_1,dae1,env4));
      then
        (cache,v,Interactive.SYMBOLTABLE(p,aDep,sp,ic_1,vars,cf,lf));

  end matchcontinue;
end getBuiltinAttribute;

protected function setBuildTime " sets the build time of a class. This is done using traverseClasses and not using updateProgram, because updateProgram updates
edit times"
  input Absyn.Program p;
  input Absyn.Path path;
  output Absyn.Program outP;
algorithm
  ((outP,_,_)) := Interactive.traverseClasses(p, NONE, setBuildTimeVisitor, path, false /* Skip protected */);
end setBuildTime;

protected function setBuildTimeVisitor "Visitor function to set build time"
  input tuple<Absyn.Class, Option<Absyn.Path>,Absyn.Path> inTpl;
  output tuple<Absyn.Class, Option<Absyn.Path>,Absyn.Path> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
  local String name; Boolean p,f,e,ro; Absyn.Restriction r; Absyn.ClassDef cdef; 
    String fname; Integer i1,i2,i3,i4;
    Absyn.Path path2,path;
    Absyn.TimeStamp ts;
   
    case((Absyn.CLASS(name,p,f,e,r,cdef,Absyn.INFO(fname,ro,i1,i2,i3,i4,ts)),SOME(path2),path)) 
      equation
        true = ModUtil.pathEqual(Absyn.joinPaths(path2,Absyn.IDENT(name)),path);
        ts =Absyn.setTimeStampBool(ts,false);
      then ((Absyn.CLASS(name,p,f,e,r,cdef,Absyn.INFO(fname,ro,i1,i2,i3,i4,ts)),SOME(path),path));
    case(inTpl) then inTpl;
      
    case((Absyn.CLASS(name,p,f,e,r,cdef,Absyn.INFO(fname,ro,i1,i2,i3,i4,ts)),NONE,path)) 
      equation
        true = ModUtil.pathEqual(Absyn.IDENT(name),path);
        ts =Absyn.setTimeStampBool(ts,false);
      then ((Absyn.CLASS(name,p,f,e,r,cdef,Absyn.INFO(fname,ro,i1,i2,i3,i4,ts)),NONE,path));
    case(inTpl) then inTpl;  
  end matchcontinue;
end setBuildTimeVisitor;

protected function extractNoCleanCommand "Function: extractNoCleanCommand
"
input Exp.Exp inexpl;
output String outString;
algorithm outString := matchcontinue(inexpl)
  local Boolean noclean; String str;
  case(Exp.BCONST(true)) then "noclean";
  case(_) then "";
  end matchcontinue;
end extractNoCleanCommand;

protected function getWithinStatement " function getWithinStatement
To get a correct Within-path with unknown input-path.
"
  input Absyn.Path ip;
  output Absyn.Within op;
algorithm op :=  matchcontinue(ip)
  local Absyn.Path path;
  case(path) equation path = Absyn.stripLast(path); then Absyn.WITHIN(path);
  case(path) then Absyn.TOP;
end matchcontinue;
end getWithinStatement;

protected function compileOrNot " function compileOrNot
This function compares last-build-time vs last-edit-time, and if we have edited since we built last time 
it fails. 
"
input Absyn.Class classIn;
algorithm _:= matchcontinue(classIn)
  local 
    Absyn.Class c1;
    Absyn.Info nfo;
    Real tb,te;
    case(c1 as Absyn.CLASS(info = nfo as Absyn.INFO(buildTimes = Absyn.TIMESTAMP(tb,te))))
    equation
    true = (tb >.te);
     then ();
    case(_) then fail();    
end matchcontinue;
end compileOrNot;

protected function subtractDummy 
"if $dummy is present in Variables, subtract 1 from equation and variable size, otherwise not"
  input DAELow.Variables vars;
  input Integer eqnSize;
  input Integer varSize;
  output Integer outEqnSize;
  output Integer outVarSize;
algorithm
  (outEqnSize,outVarSize) := matchcontinue(vars,eqnSize,varSize)
    case(vars,eqnSize,varSize) equation
      (_,_) = DAELow.getVar(Exp.CREF_IDENT("$dummy",Exp.OTHER(),{}),vars);
    then (eqnSize-1,varSize-1);
    case(vars,eqnSize,varSize) then (eqnSize,varSize);
  end matchcontinue;
end subtractDummy;

public function dumpXMLDAE "function dumpXMLDAE
 author: fildo
 This function outputs the DAE system corresponding to a specific model."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable3;
  output String xml_filename "initFileName";
  output String xml_contents;
algorithm
  (outCache,outInteractiveSymbolTable3,xml_filename,xml_contents):=
  matchcontinue (inCache,inEnv,inExp,inInteractiveSymbolTable,inMsg)
    local
      Boolean cdToTemp,asInSimulationCode;
      Real starttime_r,stoptime_r,interval_r,tolerance_r;
      String file_dir,cname_str,init_filename,method_str,filenameprefix,makefilename,oldDir,tempDir;
      list<SCode.Class> sp;
      list<Interactive.InstantiatedClass> ic;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      list<Env.Frame> env;
      Absyn.Path classname;
      Absyn.Program p;
      DAELow.DAELow indexed_dlow_1;
      Env.Cache cache;
      Exp.Exp exp,fileprefix,storeInTemp,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals;
      Exp.ComponentRef cr;
      Interactive.InteractiveSymbolTable st,st_1;
      Ceval.Msg msg;
      Values.Value ret_val;
    case (cache,env,(exp as Exp.CALL(path = Absyn.IDENT(name = _),
      expLst = {Exp.CODE(Absyn.C_TYPENAME(classname),_),Exp.BCONST(bool=true),addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals,fileprefix,storeInTemp})),
      (st_1 as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local
        Boolean x;
        Integer[:] ass1,ass2;
        DAE.DAElist dae_1,dae;
        DAELow.DAELow dlow,dlow_1,indexed_dlow,indexed_dlow_1;
        list<Integer>[:] m,mT;
        list<DAE.Element> dael;
        list<Interactive.InstantiatedClass> ic_1,ic;
        list<SCode.Class> p_1,sp;
        list<list<Integer>> comps;
        list<Absyn.Path> funcpaths; 
        list<DAE.Element> funcelems;
      equation
        //asInSimulationCode==true => it's necessary to do all the translation's steps before dumping with xml
        _ = Error.getMessagesStr() "Clear messages";
        (cache,Values.BOOL(cdToTemp),SOME(st)) = Ceval.ceval(cache,env, storeInTemp, true, SOME(st_1), NONE, msg);
        oldDir = System.pwd();
        changeToTempDirectory(cdToTemp);
        (cache,filenameprefix) = extractFilePrefix(cache,env, fileprefix, st, msg);
        cname_str = Absyn.pathString(classname);
        p_1 = SCode.elaborate(p);
        (cache,env,_,dae_1) = Inst.instantiateClass(cache, InstanceHierarchy.emptyInstanceHierarchy, p_1, classname);
        ((dae as DAE.DAE(dael))) = DAE.transformIfEqToExpr(dae_1);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(classname,dael,env));
        dlow = DAELow.lower(dae, true, true);
        m = DAELow.incidenceMatrix(dlow);
        mT = DAELow.transposeMatrix(m);
        (ass1,ass2,dlow_1,m,mT) = DAELow.matchingAlgorithm(dlow, m, mT, (DAELow.INDEX_REDUCTION(),DAELow.EXACT(), DAELow.REMOVE_SIMPLE_EQN()));
        (comps) = DAELow.strongComponents(m, mT, ass1, ass2);
        indexed_dlow = DAELow.translateDae(dlow_1,NONE());
        indexed_dlow_1 = DAELow.calculateValues(indexed_dlow);
        xml_filename = Util.stringAppendList({filenameprefix,".xml"});
        funcpaths = SimCodegen.getCalledFunctions(dae, indexed_dlow_1);
        funcelems = SimCodegen.generateFunctions2(p_1, funcpaths);
        Print.clearBuf();
        XMLDump.dumpDAELow(indexed_dlow_1,funcpaths,funcelems,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals);
        xml_contents = Print.getString();
        Print.clearBuf();
        System.writeFile(xml_filename,xml_contents);
      then
        (cache,st,xml_contents,stringAppend("The model has been dumped to xml file: ",xml_filename));
        
    case (cache,env,(exp as Exp.CALL(path = Absyn.IDENT(name = _),
      expLst = {Exp.CODE(Absyn.C_TYPENAME(classname),_),Exp.BCONST(bool=false),addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals,fileprefix,storeInTemp})),
      (st_1 as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local
        Boolean x;
        DAE.DAElist dae_1,dae;
        DAELow.DAELow dlow,dlow_1;
        list<Integer>[:] m,mT;
        list<DAE.Element> dael;
        list<Interactive.InstantiatedClass> ic_1,ic;
        list<SCode.Class> p_1,sp;
        list<Absyn.Path> funcpaths;
        list<DAE.Element> funcelems;
      equation
        //asInSimulationCode==false => it's NOT necessary to do all the translation's steps before dumping with xml
        _ = Error.getMessagesStr() "Clear messages";
        (cache,Values.BOOL(cdToTemp),SOME(st)) = Ceval.ceval(cache,env, storeInTemp, true, SOME(st_1), NONE, msg);
        oldDir = System.pwd();
        changeToTempDirectory(cdToTemp);
        (cache,filenameprefix) = extractFilePrefix(cache,env, fileprefix, st, msg);
        cname_str = Absyn.pathString(classname);
        p_1 = SCode.elaborate(p);
        (cache,env,_,dae_1) = Inst.instantiateClass(cache, InstanceHierarchy.emptyInstanceHierarchy, p_1, classname);
        ((dae as DAE.DAE(dael))) = DAE.transformIfEqToExpr(dae_1);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(classname,dael,env));
        dlow = DAELow.lower(dae, true, true);
        m = DAELow.incidenceMatrix(dlow);
        mT = DAELow.transposeMatrix(m);
        (_,_,dlow_1,m,mT) = DAELow.matchingAlgorithm(dlow, m, mT, (DAELow.INDEX_REDUCTION(),DAELow.EXACT(), DAELow.REMOVE_SIMPLE_EQN()));
        xml_filename = Util.stringAppendList({filenameprefix,".xml"});
        funcpaths = SimCodegen.getCalledFunctions(dae, dlow_1);
        funcelems = SimCodegen.generateFunctions2(p_1, funcpaths);
        Print.clearBuf();
        XMLDump.dumpDAELow(dlow_1,funcpaths,funcelems,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals);        
        xml_contents = Print.getString();
        Print.clearBuf();
        System.writeFile(xml_filename,xml_contents);
      then
        (cache,st,xml_contents,stringAppend("The model has been dumped to xml file: ",xml_filename));
    case (_,_,_,_,_)
      then
        fail();
  end matchcontinue;
end dumpXMLDAE;

protected function getClassnamesInClassList
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  output list<String> outStrings;
algorithm
  outStrings :=
  matchcontinue (inPath,inProgram,inClass)
    local
      list<String> strlist;
      list<String> res;
      list<Absyn.ClassPart> parts;
      Absyn.Class cdef;
      Absyn.Path newpath,inmodel,path;
      Absyn.Program p;
      String name, baseClassName;
    case (_,_,Absyn.CLASS(body = Absyn.PARTS(classParts = parts)))
      equation
        strlist = Interactive.getClassnamesInParts(parts);
      then
        strlist;

    case (inmodel,p,Absyn.CLASS(body = Absyn.DERIVED(typeSpec=Absyn.TPATH(path = path))))
      equation
      then
        {};

    case (inmodel,p,Absyn.CLASS(body = Absyn.OVERLOAD(_, _)))
      equation        
      then {};

    case (inmodel,p,Absyn.CLASS(body = Absyn.ENUMERATION(_, _)))
      equation        
      then {};

    case (inmodel,p,Absyn.CLASS(body = Absyn.CLASS_EXTENDS(baseClassName, _, _, parts)))
      equation
        strlist = Interactive.getClassnamesInParts(parts);        
      then strlist;

    case (inmodel,p,Absyn.CLASS(body = Absyn.PDER(_,_)))
      equation        
      then {};
        
  end matchcontinue;
end getClassnamesInClassList;

protected function joinPaths
  input String child;
  input Absyn.Path parent;
  output Absyn.Path outPath;
algorithm
  outPath :=
  matchcontinue (child, parent)
    local
      Absyn.Path r, res;
      String c;
    case (c, r)
      equation
        res = Absyn.joinPaths(r, Absyn.IDENT(c));
      then res;
  end matchcontinue;
end joinPaths;

protected function getAllClassPathsRecursive 
"@author adrpo
 Returns all paths of the classes recursively defined in a given class with the specified path."
  input Absyn.Path inPath "the given class path"; 
  input Absyn.Program inProgram "the program";
  output list<Absyn.Path> outPaths;
algorithm
  outPaths :=
  matchcontinue (inPath,inProgram)
    local
      Absyn.Class cdef;
      String parent_string, s;
      list<String> strlst;  
      Absyn.Program p;
      list<Absyn.Path> result_path_lst, result; 
    case (inPath, p)
      equation
        cdef = Interactive.getPathedClassInProgram(inPath, p);
        strlst = getClassnamesInClassList(inPath, p, cdef);
        result_path_lst = Util.listMap1(strlst, joinPaths, inPath);
        result = Util.listFlatten(Util.listMap1(result_path_lst, getAllClassPathsRecursive, p));
      then
        inPath::result;
    case (inPath, _) 
      equation
        parent_string = Absyn.pathString(inPath);
        s = Error.printMessagesStr();
        s = Util.stringAppendList({parent_string,"->","PROBLEM GETTING CLASS PATHS: ", s, "\n"});
        print(s);
      then {};
  end matchcontinue;
end getAllClassPathsRecursive;

public function checkAllModelsRecursive 
"@author adrpo 
 checks all models and returns number of variables and equations"
	input Env.Cache inCache;
	input Env.Env inEnv;
  input Absyn.Path className;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm
  (outCache,outValue,outInteractiveSymbolTable):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg)
    local
      list<Absyn.Path> allClassPaths;
      Absyn.Path className;
      list<SCode.Class> sp;
      list<Interactive.InstantiatedClass> ic;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      Env.Cache cache;
      String ret;
      list<Env.Frame> env;
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation          
        allClassPaths = getAllClassPathsRecursive(className, p);
        // print ("All paths: \n" +& Util.stringDelimitList(Util.listMap(allClassPaths, Absyn.pathString), "\n") +& "\n");
        checkAll(cache, env, allClassPaths, st, msg);
      then
        (cache,Values.STRING("done"),st);
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation 
        ret = stringAppend("Error checking: ", Absyn.pathString(className));
    then
      (cache,Values.STRING(ret),st);
  end matchcontinue;
end checkAllModelsRecursive;

function failOrSuccess
"@author adrpo"
  input String inStr;
  output String outStr;
algorithm
  outStr := matchcontinue(inStr)
    local Integer res;
    case (inStr)
      equation
        res = System.stringFind(inStr, "successfully");
        true = (res >= 0);
      then "OK";
    case (_) then "FAILED!";
  end matchcontinue;
end failOrSuccess;    

function checkAll
"@author adrpo 
 checks all models and returns number of variables and equations"
	input Env.Cache inCache;
	input Env.Env inEnv;
  input list<Absyn.Path> allClasses;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
algorithm
  (outCache,outValue,outInteractiveSymbolTable):=
  matchcontinue (inCache,inEnv,allClasses,inInteractiveSymbolTable,inMsg)
    local
      list<Absyn.Path> rest;
      Absyn.Path className;
      list<SCode.Class> sp;
      list<Interactive.InstantiatedClass> ic;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      Env.Cache cache;
      String ret, str, s;
      list<Env.Frame> env;
      Real t1, t2, elapsedTime;
      Absyn.ComponentRef cr;
      Absyn.Class c;
    case (cache,env,{},_,_) then ();
                  
    case (cache,env,className::rest,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)      
      equation
        c = Interactive.getPathedClassInProgram(className, p);
        // filter out partial classes
        Absyn.CLASS(partialPrefix = false) = c; 
        cr = Absyn.pathToCref(className); 
        // filter out packages 
        false = Interactive.isPackage(cr, p);
        // filter out functions 
        // false = Interactive.isFunction(cr, p);        
        // filter out types 
        false = Interactive.isType(cr, p);
        print("Checking: " +& Dump.unparseClassAttributesStr(c) +& " " +& Absyn.pathString(className) +& "... ");
        t1 = clock();
        (cache,Values.STRING(str),_) = checkModel(cache, env, className, st, msg);        
        t2 = clock(); elapsedTime = t2 -. t1; s = realString(elapsedTime);        
        print (s +& " seconds -> " +& failOrSuccess(str) +& "\n\t");
        print (System.stringReplace(str, "\n", "\n\t"));
        print ("\n");
        checkAll(cache, env, rest, st, msg);
      then
        ();

    case (cache,env,className::rest,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      equation
        c = Interactive.getPathedClassInProgram(className, p);                  
        print("Skipping: " +& Dump.unparseClassAttributesStr(c) +& " " +& Absyn.pathString(className) +& "... \n");                
        checkAll(cache, env, rest, st, msg);
      then
        ();
  end matchcontinue;     
end checkAll;

public function buildModelBeast "function buildModelBeast
 copy & pasted by: Otto
 translates and builds the model by running compiler script on the generated makefile"
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Exp.Exp inExp;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  output Env.Cache outCache;
  output String outString1 "className";
  output String outString2 "method";
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable3;
  output String outString4 "initFileName";
algorithm 
  (outCache,outString1,outString2,outInteractiveSymbolTable3,outString4):=
  matchcontinue (inCache,inEnv,inExp,inInteractiveSymbolTable,inMsg)
    local
      Values.Value ret_val;
      Interactive.InteractiveSymbolTable st,st_1,st2;
      DAELow.DAELow indexed_dlow_1;
      list<String> libs;
      String prefix_str,file_dir,cname_str,init_filename,method_str,filenameprefix,makefilename,oldDir,tempDir,options_str;
      Absyn.Path classname,w;
      Absyn.Program p,p2;
      Absyn.Class cdef;
      list<Interactive.CompiledCFunction> cf;
      Real starttime_r,stoptime_r,interval_r,tolerance_r;
      list<Env.Frame> env;
      Exp.Exp exp,starttime,stoptime,interval,method,tolerance,fileprefix,storeInTemp,noClean,options;
      Exp.ComponentRef cr;      
      list<SCode.Class> sp;
      AbsynDep.Depends aDep;
      list<Interactive.InstantiatedClass> ic;
      list<Interactive.InteractiveVariable> iv;      
      Ceval.Msg msg;
      Absyn.Within win1;
      Env.Cache cache;
      Boolean cdToTemp;
    case (cache,env,(exp as Exp.CALL(path = Absyn.IDENT(name = _),expLst = ({Exp.CODE(Absyn.C_TYPENAME(classname),_),starttime,stoptime,interval,tolerance, method,fileprefix,storeInTemp,noClean,options}))),(st_1 as Interactive.SYMBOLTABLE(ast = p  as Absyn.PROGRAM(globalBuildTimes=ts),explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg)
      local Absyn.TimeStamp ts;
        Real r1,r2;
        String s1,s2,s3,makefilename;
      equation 
        cdef = Interactive.getPathedClassInProgram(classname,p);        
        _ = Error.getMessagesStr() "Clear messages";
        (cache,Values.BOOL(cdToTemp),SOME(st)) = Ceval.ceval(cache,env, storeInTemp, true, SOME(st_1), NONE, msg);
        oldDir = System.pwd();
        changeToTempDirectory(cdToTemp);
        (cache,ret_val,st,indexed_dlow_1,libs,file_dir) = translateModel(cache,env, classname, st_1, msg, fileprefix,true);
        cname_str = Absyn.pathString(classname);
        (cache,init_filename,starttime_r,stoptime_r,interval_r,tolerance_r,method_str,options_str) = calculateSimulationSettings(cache,env, exp, st, msg, cname_str);
        (cache,filenameprefix) = extractFilePrefix(cache,env, fileprefix, st, msg);
        SimCodegen.generateInitData(indexed_dlow_1, classname, filenameprefix, init_filename, starttime_r, stoptime_r, interval_r,tolerance_r,method_str,options_str);
        makefilename = generateMakefilename(filenameprefix);
        Debug.fprintln("dynload", "buildModel: about to compile model " +& filenameprefix +& ", " +& file_dir);
        compileModel(filenameprefix, libs, file_dir, "");
        Debug.fprintln("dynload", "buildModel: Compiling done.");
        /* SimCodegen.generateMakefileBeast(makefilename, filenameprefix, libs, file_dir); */
        win1 = getWithinStatement(classname);
        p2 = Absyn.PROGRAM({cdef},win1,ts);
        s3 = extractNoCleanCommand(noClean);
        compileModel(filenameprefix, libs, file_dir,s3); 
        _ = System.cd(oldDir);
        /* (p as Absyn.PROGRAM(globalBuildTimes=Absyn.TIMESTAMP(r1,r2))) = Interactive.updateProgram2(p2,p,false); */       
        st2 = st; // Interactive.replaceSymbolTableProgram(st,p);
      then
        (cache,filenameprefix,"",st2,"");
    case (_,_,_,_,_)
      then
        fail();
  end matchcontinue;
end buildModelBeast;

public function getValueString "
Constant evaluates Expression and returns a string representing value. 
"
  input Exp.Exp e1;
  output String ostring;
algorithm ostring := matchcontinue( e1)
  case(e1)
    local Values.Value val;
      String ret;
    equation
      (_,val as Values.STRING(ret),_) = Ceval.ceval(Env.emptyCache(),Env.emptyEnv, e1,true,NONE,NONE,Ceval.MSG());
    then
      ret;
  case(e1)
    local Values.Value val;
      String ret;
    equation
      (_,val,_) = Ceval.ceval(Env.emptyCache(),Env.emptyEnv, e1,true,NONE,NONE,Ceval.MSG());
      ret = Values.printValStr(val);
    then
      ret;
      
end matchcontinue;
end getValueString;

public function generateMakefileHeader
  output String hdr;
algorithm
  hdr := matchcontinue ()
    local
      String omhome,header,ccompiler,cxxcompiler,linker,exeext,dllext,cflags,ldflags;
    case()
      equation
        ccompiler = System.getCCompiler();
        cxxcompiler = System.getCXXCompiler();
        linker = System.getLinker();
        exeext = System.getExeExt();
        dllext = System.getDllExt();
        omhome = Settings.getInstallationDirectoryPath();
        omhome = System.trim(omhome, "\""); //Remove any quotation marks from omhome.
        cflags = System.getCFlags();
        ldflags = System.getLDFlags();
        header = Util.stringAppendList({
          "#Makefile generated by OpenModelica\n\n",
          "CC=",ccompiler,"\n",
          "CXX=",cxxcompiler,"\n",
          "LINK=",linker,"\n",
          "EXEEXT=",exeext,"\n",
          "DLLEXT=",dllext,"\n",
          "CFLAGS= -I\"",omhome,"/include\" ", cflags ,"\n",
          "LDFLAGS= -L\"",omhome,"/lib\" ", ldflags ,"\n"
          });
    then header;
  end matchcontinue;
end generateMakefileHeader;

protected function generateMakefilename "function generateMakefilename"
  input String filenameprefix;
  output String makefilename;
algorithm 
  makefilename := Util.stringAppendList({filenameprefix,".makefile"});
end generateMakefilename;

protected function generateFunctionName
"@author adrpo: 
 generate the function name from a path."
  input Absyn.Path functionPath;
  output String functionName; 
algorithm
  functionName := ModUtil.pathStringReplaceDot(functionPath, "_");
end generateFunctionName;

public function cevalGenerateFunction "function: cevalGenerateFunction
  Generates code for a given function name."
	input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  output Env.Cache outCache;
  output String functionName;
algorithm 
  (outCache,functionName) :=
  matchcontinue (inCache,inEnv,inPath) 
    local
      String pathstr,gencodestr,cfilename,makefilename,omhome,str,libsstr;
      list<Env.Frame> env;
      Absyn.Path path;
      Env.Cache cache;
      String MakefileHeader;
      list<String> libs;

    case (cache, env, path)
      equation 
        false = RTOpts.debugFlag("nogen");
        (cache,false) = Static.isExternalObjectFunction(cache,env,path); //ext objs functions not possible to Ceval.ceval.
        pathstr = generateFunctionName(path); 
        Debug.fprintln("ceval", "/*- Ceval.cevalGenerateFunction starting*/");        
        (cache,gencodestr,_,libs,_) = cevalGenerateFunctionStr(cache, path, env, {}, {});
        cfilename = stringAppend(pathstr, ".c");
        str = Util.stringAppendList(
          {"#include \"modelica.h\"\n#include <stdio.h>\n#include <stdlib.h>\n#include <errno.h>\n\n",
           "#if defined(_MSC_VER)\n",
           "  #define DLLExport   __declspec( dllexport ) \n",
           "#else \n",
           "  #define DLLExport /* nothing */\n",
           "#endif \n\n",
           "#if !defined(MODELICA_ASSERT)\n",
           "  #define MODELICA_ASSERT(cond,msg) { if (!(cond)) fprintf(stderr,\"Modelica Assert: %s!\\n\", msg); }\n",
           "#endif\n",
           "#if !defined(MODELICA_TERMINATE)\n",
           "  #define MODELICA_TERMINATE(msg) { fprintf(stderr,\"Modelica Terminate: %s!\\n\", msg); fflush(stderr); }\n",
           "#endif\n\n\n",
           gencodestr});
        System.writeFile(cfilename, str);
        Debug.fprintln("dynload", "cevalGenerateFunction: generating makefile for " +& pathstr);
        makefilename = generateMakefilename(pathstr);
        omhome = Settings.getInstallationDirectoryPath();
        omhome = System.trim(omhome, "\""); //Remove any quotation marks from omhome.
        MakefileHeader = generateMakefileHeader();
        libs = Util.listUnion(libs, libs); // un-double the libs
        libsstr = Util.stringDelimitList(libs, " ");
        str = Util.stringAppendList(
          {MakefileHeader,"\n.PHONY: ",pathstr,"\n",
          pathstr,": ",cfilename,"\n","\t $(LINK)",
          " $(CFLAGS)",
          " -o ",pathstr,"$(DLLEXT) ",cfilename,
          " $(LDFLAGS)",
          " ",libsstr," -lm \n"});
        System.writeFile(makefilename, str);
        compileModel(pathstr, {}, "", "");
      then
        (cache,pathstr);
    case (cache, env, path)
      equation 
        false = RTOpts.debugFlag("nogen");      
        (cache,false) = Static.isExternalObjectFunction(cache,env,path);    
        pathstr = generateFunctionName(path);
        pathstr = stringAppend("/*- Ceval.cevalGenerateFunction failed(", pathstr);
        pathstr = stringAppend(pathstr,")*/\n");
        Debug.fprint("failtrace", pathstr);
      then
        fail();
  end matchcontinue;
end cevalGenerateFunction;

protected function cevalGenerateFunctionStr "function: cevalGenerateFunctionStr
  Generates a function with the given path, and all functions that are called
  within that function. The two string lists contains names of functions and
  records already generated, which won\'t be generated again."
 	input Env.Cache inCache;
  input Absyn.Path inPath;
  input Env.Env inEnv;
  input list<Absyn.Path> inAbsynPathLst;
  input list<String> inRecordTypes;
  output Env.Cache outCache;
  output String outString;
  output list<Absyn.Path> outAbsynPathLst;
  output list<String> outLibs;
  output list<String> outRecordTypes;
algorithm 
  (outCache,outString,outAbsynPathLst,outLibs,outRecordTypes):=
  matchcontinue (inCache,inPath,inEnv,inAbsynPathLst,inRecordTypes)
    local
      Absyn.Path gfmember,path;
      list<Env.Frame> env,env_1,env_2;
      list<Absyn.Path> gflist,calledfuncs,gflist_1;
      SCode.Class cls;
      list<DAE.Element> d;
      list<String> debugfuncs,calledfuncsstrs,libs,libs_2,calledfuncsstrs_1,rt,rt_1,rt_2;
      String debugfuncsstr,funcname,funccom,thisfuncstr,resstr;
      DAE.DAElist d_1;
      Env.Cache cache;
    case (cache,path,env,gflist,rt) /* If getmember succeeds, path is in generated functions list, so do nothing */ 
      equation 
        gfmember = Util.listGetMemberOnTrue(path, gflist, ModUtil.pathEqual);
      then
        (cache,"",gflist,{},rt);
    case (cache,path,env,gflist,rt) /* If getmember fails, path is not in generated functions list, hence generate it */ 
      equation 
        false = RTOpts.debugFlag("nogen");
        failure(_ = Util.listGetMemberOnTrue(path, gflist, ModUtil.pathEqual));
        Debug.fprintln("ceval", "/*- Ceval.cevalGenerateFunctionStr starting*/");
        (cache,cls,env_1) = Lookup.lookupClass(cache,env, path, false);
        Debug.fprintln("ceval", "/*- Ceval.cevalGenerateFunctionStr instantiating*/");
        (cache,env_2,_,d) = 
        Inst.implicitFunctionInstantiation(
           cache, env_1, InstanceHierarchy.emptyInstanceHierarchy,
           Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, cls, {});
        Debug.fprint("ceval", "/*- Ceval.cevalGenerateFunctionStr getting functions: ");
        calledfuncs = SimCodegen.getCalledFunctionsInFunction(path, gflist, DAE.DAE(d));
        gflist = path :: gflist; // In case the function is recursive
        calledfuncs = Util.listSetDifference(calledfuncs, gflist); // Filter out things we already know will be ignored...
        debugfuncs = Util.listMap(calledfuncs, Absyn.pathString);
        debugfuncsstr = Util.stringDelimitList(debugfuncs, ", ");
        Debug.fprint("ceval", debugfuncsstr);
        Debug.fprintln("ceval", "*/");
        (cache,calledfuncsstrs,gflist,libs_2, rt_1) = cevalGenerateFunctionStrList(cache,calledfuncs, env, gflist, rt);
        Debug.fprint("ceval", "/*- Ceval.cevalGenerateFunctionStr prefixing dae */");
        d_1 = ModUtil.stringPrefixParams(DAE.DAE(d));
        Print.clearBuf();
        funcname = Absyn.pathString(path);
        funccom = Util.stringAppendList({"/*---FUNC: ",funcname," ---*/\n\n"});
        Print.printBuf(funccom);
        Debug.fprintln("ceval", "/*- Ceval.cevalGenerateFunctionStr generating functions */");
        (libs,rt_2) = Codegen.generateFunctions(d_1,rt_1);
        thisfuncstr = Print.getString();
        calledfuncsstrs_1 = Util.listAppendElt(thisfuncstr, calledfuncsstrs);
        resstr = Util.stringDelimitList(calledfuncsstrs_1, "\n\n");
        libs = listAppend(libs, libs_2);
      then
        (cache,resstr,(path :: gflist),libs,rt_2);
    case (_,path,env,_,_)
      local String ss1;
      equation 
        true = RTOpts.debugFlag("nogen");
        ss1 = Absyn.pathString(path);
        ss1 = Util.stringAppendList({"/*- Ceval.cevalGenerateFunctionStr failed( ",ss1," ) set \"nogen\" flag to false */\n"});
        Debug.fprint("failtrace", ss1);
      then
        fail();
    case (_,path,env,_,_)
      local String ss1;
      equation 
        false = RTOpts.debugFlag("nogen");
        ss1 = Absyn.pathString(path);
        ss1 = Util.stringAppendList({"/*- Ceval.cevalGenerateFunctionStr failed( ",ss1," )*/\n"});
        Debug.fprint("failtrace", ss1);
      then
        fail();
  end matchcontinue;
end cevalGenerateFunctionStr;

protected function cevalGenerateFunctionStrList "function: cevalGenerateFunctionStrList
  Generates code for several functions."
	input Env.Cache inCache;
  input list<Absyn.Path> inAbsynPathLst1;
  input Env.Env inEnv2;
  input list<Absyn.Path> inAbsynPathLst3;
  input list<String> inRecordTypes;
  output Env.Cache outCache;
  output list<String> outStringLst;
  output list<Absyn.Path> outAbsynPathLst;
  output list<String> outLibs;
  output list<String> outRecordTypes;
algorithm 
  (outCache,outStringLst,outAbsynPathLst,outLibs,outRecordTypes):=
  matchcontinue (inCache,inAbsynPathLst1,inEnv2,inAbsynPathLst3,inRecordTypes)
    local
      list<Env.Frame> env;
      list<Absyn.Path> gflist,gflist_1,gflist_2,rest;
      String firststr;
      list<String> reststr, rt, rt_1, rt_2;
      Absyn.Path first;
      Env.Cache cache;
      list<String> libs_1,libs_2;
    case (cache,{},env,gflist,rt) then (cache,{},gflist,{},rt);
    case (cache,(first :: rest),env,gflist,rt)
      equation
        (cache,firststr,gflist_1,libs_1,rt_1) = cevalGenerateFunctionStr(cache,first, env, gflist,rt);
        (cache,reststr,gflist_2,libs_2,rt_2) = cevalGenerateFunctionStrList(cache,rest, env, gflist_1,rt_1);
        libs_1 = listAppend(libs_1, libs_2);
      then
        (cache,(firststr :: reststr),gflist_2,libs_1,rt_2);
  end matchcontinue;
end cevalGenerateFunctionStrList;

end CevalScript;