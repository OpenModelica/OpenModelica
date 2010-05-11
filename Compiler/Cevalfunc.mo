package Cevalfunc
"Copyright (C) MathCore Engineering AB, 2007

 Author: Bjorn Zachrisson

  file:   Cevalfunc.mo
  module:      MATHCORE
  description: This module constant evaluates userdefined functions, speeds up instantination process.
  It includes Constant evaluations of function and algorithm statements.
  RCS: $Id$
  
  TODO: implement ALG_RETURN and ALG_BREAK when evaluating statements

  "
public import Env;
public import Values;
public import Absyn;
public import DAE;
public import SCode;
public import Prefix;
public import Connect;
public import ClassInf;
public import ConnectionGraph;
public import RTOpts;
public import HashTable2;

protected import Ceval;
protected import Util;
protected import Error;
protected import Exp;
protected import Debug;
protected import Lookup;
protected import Static;
protected import Inst;
protected import InnerOuter;
protected import Types;
protected import UnitAbsyn;
protected import ValuesUtil;
protected import ErrorExt;
protected import OptManager;
protected import Dump;

public function cevalUserFunc "Function: cevalUserFunc
This is the main funciton for the class. It will take a userdefined function and \"try\" to
evaluate it. This is to prevent multiple compilation of c files.

NOTE: this function operates on Absyn and not DAE therefore static elaboration on expressions is done twice
"
  input Env.Env env "enviroment for the user-function";
  input DAE.Exp callExp "DAE.CALL(userFunc)";
  input list<Values.Value> inArgs "arguments evaluated so no envirnoment is needed";
  input SCode.Class sc "function body";
  input DAE.DAElist daeList;
  output Values.Value outVal "The output value";

algorithm
  outVal := matchcontinue(env,callExp,inArgs,sc,daeList)
      local
        list<SCode.Element> elementList;
        Env.Env env1,env2,env3;
        Values.Value retVal;
        list<Values.Value> retVals;
        Absyn.Path funcpath, basefuncpath;
        list<DAE.Exp> crefArgs;
        String str;
        HashTable2.HashTable ht2;
        SCode.Class c;
        list<tuple<DAE.ComponentRef, DAE.Exp>> replacements;
    // Case for derived functions without modifications    
    case(env,(callExp as DAE.CALL(path = funcpath,expLst = crefArgs)),inArgs,
         sc as SCode.CLASS(partialPrefix=false,restriction=SCode.R_FUNCTION(),
                           classDef=SCode.DERIVED(typeSpec=Absyn.TPATH(path=basefuncpath), 
                             modifications=SCode.MOD(subModLst={}))),daeList)
      equation
        (_,c,env2)=Lookup.lookupClass(Env.emptyCache(),env,basefuncpath,true);
        retVal = cevalUserFunc(env2,callExp,inArgs,c,daeList);
      then
        retVal;                         
    case(env,(callExp as DAE.CALL(path = funcpath,expLst = crefArgs)),inArgs,
         sc as SCode.CLASS(partialPrefix=false,restriction=SCode.R_FUNCTION(),
                           classDef=SCode.PARTS(elementLst=elementList) ),daeList)
      equation
        ErrorExt.setCheckpoint("cevalUserFunc");
        true = OptManager.setOption("envCache",false);
        str = Absyn.pathString(funcpath);
        replacements = createReplacementRules(inArgs,elementList);
        ht2 = generateHashMap(replacements,HashTable2.emptyHashTable());
        str = Util.stringAppendList({"cevalfunc_",str});
        env3 = Env.openScope(env, false, SOME(str));
        env1 = extendEnvWithInputArgs(env3,elementList,inArgs,crefArgs, ht2) "also output arguments";
        // print("evalfunc env: " +& Env.printEnvStr(env) +& "\n");
        // print("evalfunc env1: " +& Env.printEnvStr(env1) +& "\n");        
        env2 = evaluateStatements(env1,sc,ht2);
        retVals = getOutputVarValues(elementList, env2);
        retVal = convertOutputVarValues(retVals);
        ErrorExt.rollBack("cevalUserFunc");
        true = OptManager.setOption("envCache",true);
      then
        retVal;

    /* Reset sideeffects */
    case(env,(callExp as DAE.CALL(path = funcpath,expLst = crefArgs)),inArgs,
        sc as SCode.CLASS(partialPrefix=false,restriction=SCode.R_FUNCTION(),
          classDef=SCode.PARTS(elementLst=elementList) ),daeList)
      equation
          ErrorExt.rollBack("cevalUserFunc");
          _ = OptManager.setOption("envCache",true);
      then fail();

    case(env,(callExp as DAE.CALL(path = funcpath,expLst = crefArgs)),inArgs,
         sc as SCode.CLASS(partialPrefix=false,restriction=SCode.R_FUNCTION(),
                           classDef=SCode.PARTS(elementLst=elementList) ),daeList)
      equation
        true = RTOpts.debugFlag("failtrace");
        _ = extendEnvWithInputArgs(env,elementList,inArgs,crefArgs,HashTable2.emptyHashTable());
        str = Absyn.pathString(funcpath);
        str = Util.stringAppendList({"- Cevalfunc.evaluateStatements failed for function /* ",str," */\n"});
        Debug.fprint("failtrace", str);
        then
          fail();
    case(env,(callExp as DAE.CALL(path = funcpath,expLst = crefArgs)),inArgs,
              sc as SCode.CLASS(partialPrefix=false,restriction=SCode.R_FUNCTION(),
                                classDef=SCode.PARTS(elementLst=elementList) ),daeList)
      equation
        true = RTOpts.debugFlag("failtrace");
        failure(_ = extendEnvWithInputArgs(env,elementList,inArgs,crefArgs,HashTable2.emptyHashTable()));
        str = Absyn.pathString(funcpath);
        str = Util.stringAppendList({"- Cevalfunc.extendEnvWithInputArgs failed for function /* ",str," */"});
        Debug.fprint("failtrace", str);
      then
        fail();
/*    case(_,(callExp as DAE.CALL(path = funcpath,expLst = crefArgs)),_,_,_)
      equation print("cevalUserFunc failed for: " +& Absyn.pathString(funcpath) +& "\n");
        then
          fail();*/
  end matchcontinue;
end cevalUserFunc;

protected function extendEnvWithInputArgs "Function: extendEnvWithInputArgs
This function will extend the current functions enviroment with the input argument(/s) 
and thier evaluated value." 
  input Env.Env env;
  input list<SCode.Element> functionElements;
  input list<Values.Value> elementValues;
  input list<DAE.Exp> crefArgs;
  input HashTable2.HashTable ht2;
  output Env.Env envOut;
algorithm 
  envOut := matchcontinue(env, functionElements, elementValues, crefArgs, ht2)
    local
      SCode.Element ele1;
      list<SCode.Element> eles1;
      SCode.Mod mod1;
      Values.Value val1,vv;
      list<Values.Value> vals1;
      Env.Env env1,env2,complexEnv;
      Env.Frame compFrame;
      String varName, str;
      DAE.Var tvar;
      DAE.Attributes tattr;
      DAE.Type ty,tty;
      DAE.Binding binding,tb;
      DAE.ExpType ety;
      DAE.Exp e1;
      list<DAE.Exp> restExps;
      Absyn.ArrayDim adim,ad;
      Absyn.ComponentRef cr;
      Absyn.Path apath;
      ClassInf.State recordconst; // for complex env construction
      list<DAE.Var> typeslst;
      Option<DAE.Type> cto; // for complex env construction, to here
      Option<Absyn.ArrayDim> optAD;

    // nothing to do
    case(env,{},_,_, ht2) then env;
    // handle extends
    case(env, (ele1 as SCode.EXTENDS(_,_,_))::eles1, vals1,restExps, ht2)
      equation
        env1 = extendEnvWithInputArgs(env,eles1,vals1,restExps, ht2);
        then
          env1;
    // handle an input component definition = call(...) where the variable is a record 
    case(env, ((ele1 as SCode.COMPONENT(component = varName, 
                                        typeSpec = Absyn.TPATH(path = apath), modifications=mod1, attributes = SCode.ATTR(direction = Absyn.INPUT() ) ))::eles1), 
              (val1::vals1),((e1 as DAE.CALL(path = _))::restExps), ht2)
      equation
        (tty as (DAE.T_COMPLEX(recordconst,typeslst,cto,_),_)) = makeComplexForEnv(e1, val1); 
        compFrame = Env.newFrame(false);
        complexEnv = makeComplexEnv({compFrame},typeslst);
        env1 = Env.extendFrameV(env,
          DAE.TYPES_VAR(varName,DAE.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
            false,tty,DAE.VALBOUND(val1),NONE()), NONE, Env.VAR_TYPED(), complexEnv);
        env2 = extendEnvWithInputArgs(env1,eles1,vals1,restExps, ht2);
      then
        env2;
    // handle an input component definition        
    case(env, ((ele1 as SCode.COMPONENT(component = varName, 
                                        typeSpec = Absyn.TPATH(path = apath), modifications=mod1, attributes = SCode.ATTR(direction = Absyn.INPUT() ,arrayDims=adim) ))::eles1), 
               (val1::vals1),((e1)::restExps), ht2)
      equation
        tty = Types.typeOfValue(val1);
        env1 = Env.extendFrameV(env,
          DAE.TYPES_VAR(varName,DAE.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
            false,tty,DAE.VALBOUND(val1),NONE()), NONE, Env.VAR_TYPED(), {});
        env2 = extendEnvWithInputArgs(env1,eles1,vals1,restExps, ht2);
      then
        env2;
    // failed to hanle an input component 
    case(_, ((ele1 as SCode.COMPONENT(component = varName, typeSpec = Absyn.TPATH(path = apath), attributes = SCode.ATTR(direction = Absyn.INPUT() ) ))::_), _,_, ht2)
      equation
        Debug.fprint("failtrace", "- Cevalfunc.extendEnvWithInputArgs with input variable failed\n");
      then
        fail();
    //******************* INPUT ARGS ENDS **********************
    //***********************************************************
    //*************** FUNCTION VARIABLE BEGINS ******************
    // no input no output, normal variables
    case(env, ((ele1 as SCode.COMPONENT(component=varName,attributes = SCode.ATTR(arrayDims=adim, direction = Absyn.BIDIR()), 
                                        typeSpec = Absyn.TPATH(path = apath), modifications = mod1)) ::eles1), 
              (vals1),restExps, ht2)
      equation
        (tty as (DAE.T_COMPLEX(_,typeslst,_,_),_) )= getTypeFromName(apath,env);
        binding = makeBinding(mod1,env,tty, ht2);
        env1 = Env.extendFrameV(env,
          DAE.TYPES_VAR(varName,DAE.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
            false,tty,binding,NONE()), NONE, Env.VAR_TYPED(), {});
        env2 = extendEnvWithInputArgs(env1,eles1,vals1,restExps, ht2);
      then
        env2;
    // any other variables (might be output) 
    case(env, ((ele1 as SCode.COMPONENT(component=varName,attributes = SCode.ATTR(arrayDims=adim), 
                      typeSpec = Absyn.TPATH(path = apath,arrayDim = _), modifications = mod1)) ::eles1), 
              (vals1),restExps, ht2)
      equation

        //since we do not have a value we use the class name to get type of variable.
        tty = getTypeFromName(apath,env);
        tty = addDims(tty,adim,env, ht2);
        (binding as DAE.VALBOUND(vv)) = makeBinding(mod1,env,tty, ht2);
        // print("extendEnvWithInputArgs -> NONE component: " +& varName +& " ty: " +& Types.printTypeStr(tty) +& " opt dim: " +& Dump.printArraydimStr(adim) +& "\n");        
        env1 = Env.extendFrameV(env, 
          DAE.TYPES_VAR(varName,DAE.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
            false,tty,binding,NONE()), NONE, Env.VAR_TYPED(), {});
        env2 = extendEnvWithInputArgs(env1,eles1,vals1,restExps, ht2);
      then
        env2;
    // failure
    case(env, (_::eles1), (vals1),restExps, ht2)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- Cevalfunc.extendEnvWithInputArgs failed!"); 
        //env1 = extendEnvWithInputArgs(env,eles1,vals1,restExps);
      then
        fail();
  end matchcontinue;
end extendEnvWithInputArgs;

protected function makeComplexForEnv "Function: makeComplexForEnv
Special case for complex structure"
  input DAE.Exp inExp "The call statement";
  input Values.Value inVal "Values.RECORD";
  output DAE.Type oType;
algorithm (oType) := matchcontinue(inExp, inVal)
  local
    Absyn.Path recordName;
    DAE.ExpType ty;
    DAE.Type cty,cty2;
    list<DAE.Var> lv,lv2;
    String pathName;
    list<Values.Value> vals;
    list<String> names;

  case(DAE.CALL(recordName,_,_,_,ty,_), inVal as Values.RECORD(_,vals,names,-1))
    equation
      (cty as (DAE.T_COMPLEX(_,lv,_,_),_)) = Types.expTypetoTypesType(ty);
      lv2 = setValuesInRecord(lv,names,vals);
      cty2 = (DAE.T_COMPLEX(ClassInf.RECORD(recordName) ,lv2 , NONE, NONE),NONE);
    then
      cty2;
end matchcontinue;
end makeComplexForEnv;

protected function setValuesInRecord "Function: setValuesInRecord 
This function sets Values in records. "
  input list<DAE.Var> inVars;  
  input list<String> invarNames; // eq 
  input list<Values.Value> inValue; // eq
  output list<DAE.Var> oType;
algorithm oType := matchcontinue(inVars,invarNames,inValue)
  local
    String varName;
    list<String> varNames;
    DAE.Attributes a ;
    Boolean p ;
    DAE.Type t ;
    DAE.Binding b;
    Values.Value val;
    list<Values.Value> values;
    DAE.Var tv,tv1;
    list<DAE.Var> tvs,rest;

  case({},_,_) then {};
  case( tv1 :: rest , varName::varNames, val::values)
    equation
      tv = setValuesInRecord2(tv1,(varName::varNames),(val::values));
      tvs = setValuesInRecord(rest,varNames,values);
    then tv::tvs;
end matchcontinue;
end setValuesInRecord;

protected function setValuesInRecord2 "Function: setValuesInRecord2
helper function for setValuesInRecord"
  input DAE.Var inVars; 
  input list<String> invarName; // eq 
  input list<Values.Value> inValue; // eq
  output DAE.Var oType;
algorithm oType := matchcontinue(inVars,invarName,inValue)
  local
    String varName3,varName2;
    list<String> varNames;
    DAE.Attributes a;
    Boolean p;
    DAE.Type t,ty2;
    DAE.Binding b;
    Values.Value val;
    list<Values.Value> values;
    DAE.Var tv,tv1;
    list<DAE.Var> tvs,rest;
    Option<DAE.Const> constOfForIteratorRange;
    list<DAE.Var> typeslst,lv2;
    list<Values.Value> vals;
    list<String> names;
    Absyn.Path fpath;
    

  // unbound, try to take the value from the type
  case(DAE.TYPES_VAR(varName2,a,p,t,DAE.UNBOUND(),constOfForIteratorRange),{},{})
    equation
      val = typeOfValue(t);
      tv = DAE.TYPES_VAR(varName2,a,p,t,DAE.VALBOUND(val),constOfForIteratorRange);
    then
      tv;
  // value bound      
  case(tv as DAE.TYPES_VAR(binding = DAE.VALBOUND(val)),{},{})
    then
      tv;
  // complex types (records)
  case(DAE.TYPES_VAR(varName3,a,p,t as (DAE.T_COMPLEX(complexVarLst = typeslst),_),b,constOfForIteratorRange),
       varName2::varNames, (val as Values.RECORD(fpath,vals,names,-1))::values)
    equation
      equality(varName3 = varName2);
      lv2 = setValuesInRecord(typeslst,names,vals);
      ty2 = (DAE.T_COMPLEX(ClassInf.RECORD(fpath) ,lv2 , NONE, NONE),NONE);
      tv = DAE.TYPES_VAR(varName3,a,p,ty2,DAE.VALBOUND(val),constOfForIteratorRange);
    then tv;
  case(DAE.TYPES_VAR(varName3,a,p,t,b,constOfForIteratorRange) ,varName2::varNames, val::values)
    equation
      equality(varName3 = varName2);
      tv = DAE.TYPES_VAR(varName3,a,p,t,DAE.VALBOUND(val),constOfForIteratorRange);
    then tv;
  case(tv1,varName3::varNames, val::values)
    equation
      tv = setValuesInRecord2(tv1,varNames,values);
    then tv;
end matchcontinue;
end setValuesInRecord2;

protected function makeComplexEnv "Function: makeComplexEnv
This function extends the env with a complex var."
  input Env.Env env;
  input list<DAE.Var> tvars; 
  output Env.Env oenv; 
algorithm oenv := matchcontinue(env, tvars)
  local 
    ClassInf.State recordconst;
    list<DAE.Var> typeslst;
    Option<DAE.Type> cto;
    String name;// matching
    DAE.Attributes attr;
    Boolean prot;
    DAE.Type ty,bc_ty;
    DAE.Binding bind;  
    Values.Value val;
    list<DAE.Var> vars;// matching end 
    DAE.Var tv;
    Env.Env env1,env2,complexEnv;
    Option<DAE.Const> constOfForIteratorRange;

  // handle nothing  
  case(env,{}) then env;

  // take and flatten the type which should be simple
  case(env, (tv as DAE.TYPES_VAR(type_ = ty))::vars)
    equation
      (ty,_) = Types.flattenArrayType(ty);
      Types.simpleType(ty);
      // print("makeComplexEnv -> 1 component: " +& name +& " ty: " +& Types.printTypeStr(ty) +& "\n");
      env1 = Env.extendFrameV(env, tv, NONE, Env.VAR_TYPED(), {});
      env2 = makeComplexEnv(env1, vars);
    then 
      env2;

  // record T_ARRAY 
  //   ArrayDim arrayDim "arrayDim"; 
  //   Type arrayType "arrayType"; 
  // end T_ARRAY;
  case(env, (tv as DAE.TYPES_VAR(name,attr,prot,ty as (DAE.T_ARRAY(_,_),_),bind,constOfForIteratorRange))::vars)
    local DAE.Type ty_flat;
    equation
      //print(" array :: fail " +& name +& ", " +& Types.printTypeStr(ty) +& "\n");
      ((ty_flat as (DAE.T_COMPLEX(_,typeslst,_,_),_)),_)=Types.flattenArrayType(ty);
      //print(" is complex tough\n");
      complexEnv = Env.newFrame(false);
      //typeslst = Util.listMap1(typeslst,addbindingtodaevar,bind); 
      complexEnv = makeComplexEnv({complexEnv},typeslst);
      // print("makeComplexEnv -> 2 component: " +& name +& " ty: " +& Types.printTypeStr(ty) +& "\n");
      env1 = Env.extendFrameV(env,
        DAE.TYPES_VAR(name,DAE.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
        false,ty,bind,constOfForIteratorRange), NONE, Env.VAR_TYPED(), complexEnv);
      env2 = makeComplexEnv(env1, vars);
      //print(" done complex array\n");
    then 
      env2;
  
  // type X = Real[x];
  case(env, (tv as DAE.TYPES_VAR(name,attr,prot,ty as (DAE.T_COMPLEX(_,typeslst,SOME(bc_ty),_),_),bind,constOfForIteratorRange))::vars)
    equation
      env2 = makeComplexEnv(env, DAE.TYPES_VAR(name,attr,prot,bc_ty,bind,constOfForIteratorRange)::vars);
    then 
      env2;

  // no base type
  case(env, (tv as DAE.TYPES_VAR(name,attr,prot,ty as (DAE.T_COMPLEX(_,typeslst,_,_),_),_,constOfForIteratorRange))::vars)
    equation
      complexEnv = Env.newFrame(false); 
      complexEnv = makeComplexEnv({complexEnv},typeslst);
      // print("makeComplexEnv -> 3 component: " +& name +& " ty: " +& Types.printTypeStr(ty) +& "\n");
      env1 = Env.extendFrameV(env,
        DAE.TYPES_VAR(name,DAE.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
          false,ty,DAE.UNBOUND(),constOfForIteratorRange), NONE, Env.VAR_TYPED(), complexEnv);
      env2 = makeComplexEnv(env1, vars);
    then 
      env2;

  // failure
  case(_,_) 
    equation 
      Debug.fprint("failtrace", "- Cevalfunc.makeComplexEnv failed\n");
    then fail();
end matchcontinue;
end makeComplexEnv;

protected function addbindingtodaevar "
add a binding to a variable in environment"
  input DAE.Var v;
  input DAE.Binding b;
output DAE.Var ov;
algorithm ov := matchcontinue(v,b)
  local
    String a1;
    DAE.Attributes a2;
    Boolean a3;
    DAE.Type a4;
    Option<DAE.Const> a6;
    
  case(DAE.TYPES_VAR(a1,a2,a3,a4,_,a6),b) then DAE.TYPES_VAR(a1,a2,a3,a4,b,a6);  
  end matchcontinue;
end addbindingtodaevar;

protected function replaceComplex "
Author BZ
Replace CREF_QUAL with correspeonding constant value if availible."
  input DAE.Exp inExp; 
  input HashTable2.HashTable ht2;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp,ht2)
    case(inExp,ht2)
      equation
         //print(" replace exp: " +& Exp.printExpStr(inExp) +& "\n");
         ((outExp,_)) = Exp.traverseExp(inExp,qualReplacer,ht2);
         //print(" replaced exp: " +& Exp.printExpStr(outExp) +& "\n");
        then
          outExp;
    case(inExp,_) then inExp;
  end matchcontinue;
end replaceComplex;

protected function qualReplacer "
The Exp.traverseExp traverse function, "
  input tuple<DAE.Exp, HashTable2.HashTable> inTpl;
  output tuple<DAE.Exp,HashTable2.HashTable> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local 
      DAE.Exp e,tmpExp; 
      Integer cnt; 
      String tmpvar;
      HashTable2.HashTable ht2; 
      DAE.ComponentRef cr;

    case(((e as DAE.CREF(componentRef = (cr as DAE.CREF_QUAL(identType=_)))),ht2))
      equation
        tmpExp = HashTable2.get(cr,ht2);
      then 
        ((tmpExp,ht2));
    case((e,ht2)) then ((e,ht2));
  end matchcontinue;
end qualReplacer;

protected function evaluateStatements "
Intermediate step for evaluating algorithms.
Takes an Envirnoment that includes function variables and a hashtable witch represents constant values for crefs.
Updates the envirnoment with the evaluated values(output)
"
  input Env.Env env;
  input SCode.Class sc;
  input HashTable2.HashTable ht2;
  output Env.Env outVal;
algorithm outVal := matchcontinue(env,sc,ht2)
  local
    list<SCode.Equation> eqs1,eqs2;
    list<SCode.Algorithm> algs1,algs2;
    Env.Env env1;
    HashTable2.HashTable ht2;

  case(env, SCode.CLASS(partialPrefix=false,restriction=SCode.R_FUNCTION(),
                        classDef=SCode.PARTS(normalEquationLst=eqs1,
                                             initialEquationLst=eqs2,
                                             normalAlgorithmLst=algs1,
                                             initialAlgorithmLst=algs2)),
       ht2)
    equation

      env1 = evaluateAlgorithmsList(env,algs1,ht2);
    then
      env1;
end matchcontinue;
end evaluateStatements;

protected function generateHashMap "
Author BZ
Construct hashmap for cref replacements."
  input list<tuple<DAE.ComponentRef, DAE.Exp>> replacements;
  input HashTable2.HashTable ht2;
  output HashTable2.HashTable ht2_out;
algorithm
  ht2_out :=  matchcontinue(replacements,ht2)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;

    case({},ht2) then ht2;
    case((cr,e)::replacements,ht2)
      equation
        ht2 = HashTable2.add((cr,e),ht2);
        ht2 = generateHashMap(replacements,ht2);
      then
        ht2;
  end matchcontinue;
end generateHashMap;

protected function evaluateAlgorithmsList "
helper function for evaluateAlgorithms"
  input Env.Env env;
  input list<SCode.Algorithm> inAlgs;
  input HashTable2.HashTable ht2;
  output Env.Env outEnv;
algorithm outEnv := matchcontinue(env,inAlgs,ht2)
  local
    list<SCode.Algorithm> algs;
    SCode.Algorithm alg;
    list<Absyn.Algorithm> alglst;
    Env.Env env1,env2;

  case(env,{},_) then env;
  case(env, (alg as SCode.ALGORITHM(alglst)) :: algs,ht2)
    equation
      (env1) = evaluateAlgorithms(env,alglst,ht2);
      (env2) = evaluateAlgorithmsList(env1,algs,ht2);
    then
      env2;
end matchcontinue;
end evaluateAlgorithmsList;

protected function evaluateAlgorithms "Function: evaluateAlgorithms
helper function for evaluateAlgorithmsList"
  input Env.Env env;
  input list<Absyn.Algorithm> inAlgs;
  input HashTable2.HashTable ht2;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(env,inAlgs,ht2)
    local
      list<Absyn.Algorithm> algs;
      Absyn.Algorithm alg;
      Env.Env env1,env2;

    case(env,{},_) then env;
    case(env, alg :: algs, ht2)
      equation
        (env1) = evaluateAlgorithm(env, alg, ht2);
        (env2) = evaluateAlgorithms(env1,algs, ht2);
      then
        env2;
    case(env,alg::algs, ht2)
      equation
        Debug.fprintln("failtrace", "- Cevalfunc.evaluateAlgorithms failed on algorithm:" +& Dump.unparseAlgorithmStr(0, Absyn.ALGORITHMITEM(alg, NONE())));
      then 
        fail();          
  end matchcontinue;  
end evaluateAlgorithms;

protected function evaluateAlgorithm "Function: evaluateAlgorithm
perform constant evaluation of Algorithm statements, eg. assign, for loop,etc.
"
  input Env.Env env;
  input Absyn.Algorithm alg;
  input HashTable2.HashTable ht2;
  output Env.Env outEnv;
algorithm 
  outEnv := matchcontinue(env,alg,ht2) 
    local 
      Absyn.Exp ae1,ae2,ae3,cond,msg;
      list<Absyn.Exp> crefexps;
      DAE.Exp econd,resExp,e1;
      Absyn.ComponentRef acr;
      DAE.Type t,ty;
      Env.Env env1,env2,env3;
      Values.Value value,start,step,stop;
      list<Values.Value> values;
      list<DAE.Type> types;
      DAE.Properties prop;
      list<Absyn.AlgorithmItem> algitemlst;
      String varName;
      String estr; 
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> elseifexpitemlist,branches1,branches2;
      tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> trueBranch;
      list<Absyn.AlgorithmItem> algitemlist,elseitemlist;

    // algorithm assign      
    case(env, Absyn.ALG_ASSIGN(ae1 as Absyn.CREF(_), ae2),ht2)
      equation
        (_,e1,DAE.PROP(t,_),_,_) = Static.elabExp(Env.emptyCache(),env,ae2,true,NONE,false);
        e1 = replaceComplex(e1,ht2); 
        (_,value,_) = Ceval.ceval(Env.emptyCache(),env, e1, true, NONE, NONE, Ceval.MSG());
        env1 = setValue(value, env, ae1);
      then
        env1;
    // assign, tuple assign
    case(env, Absyn.ALG_ASSIGN(assignComponent = Absyn.TUPLE(expressions = crefexps),value = ae1),ht2)
      equation
        (_,resExp,prop,_,_) = Static.elabExp(Env.emptyCache(),env, ae1, true, NONE,true);
        resExp = replaceComplex(resExp,ht2);
        ((DAE.T_TUPLE(types),_)) = Types.getPropType(prop);
        (_,Values.TUPLE(values),_) = Ceval.ceval(Env.emptyCache(),env, resExp, true, NONE, NONE, Ceval.MSG());
        env1 = setValues(crefexps,types,values,env);
      then
        env1;
    //while case
    case(env, Absyn.ALG_WHILE(boolExpr = ae1,whileBody = algitemlst),ht2)
      equation
        value = evaluateSingleExpression(ae1,env,NONE,ht2);
        env1  = evaluateConditionalStatement(value, ae1, algitemlst,env,ht2);
      then
        env1;
    // for loop with a range without step
    case(env, Absyn.ALG_FOR({(varName, SOME(Absyn.RANGE(start=ae1,step=NONE, stop=ae2)))},forBody = algitemlst),ht2)
      equation 
        start = evaluateSingleExpression(ae1,env,NONE,ht2);
        // constant range due to ceval of start/stop
        env1 = addForLoopScope(env,varName,start,SCode.VAR(),SOME(DAE.C_CONST()));
        stop  = evaluateSingleExpression(ae2,env1,NONE,ht2);
        step  = Values.INTEGER(1);
        env2 = evaluateForLoopRange(env1, varName, algitemlst, start, step, stop, ht2);
      then
        env2;
    // for loop with a range with step
    case(env, Absyn.ALG_FOR({(varName, SOME(Absyn.RANGE(start=ae1, step=SOME(ae2), stop=ae3)))},forBody = algitemlst),ht2)
      equation
        start = evaluateSingleExpression(ae1,env,NONE,ht2);
        // constant range due to ceval of start/stop/step
        env1 = addForLoopScope(env,varName,start,SCode.VAR(),SOME(DAE.C_CONST()));
        stop = evaluateSingleExpression(ae3,env1,NONE,ht2);
        step = evaluateSingleExpression(ae2,env1,NONE,ht2);
        env2 = evaluateForLoopRange(env1, varName, algitemlst, start, step, stop, ht2);
      then
        env2;
    // some other expression for range, such as an array!
    case(env, Absyn.ALG_FOR({(varName, SOME(ae1))},forBody = algitemlst),ht2)
      equation
        (Values.ARRAY(valueLst = values)) = evaluateSingleExpression(ae1,env,NONE,ht2);
        start = listNth(values,0);
        // constant range due to ceval of range expression
        env1 = addForLoopScope(env,varName,start,SCode.VAR(),SOME(DAE.C_CONST()));
        env2 = evaluateForLoopArray(env1, varName, values, algitemlst, ht2);
      then
        env2;
    // error for unknown range
    case(env,Absyn.ALG_FOR(iterators = {(_,SOME(ae1))}),ht2) 
      equation
        (_,e1,_,_,_) = Static.elabExp(Env.emptyCache(),env, ae1, true, NONE,true);
        estr = Exp.printExpStr(e1);
        Error.addMessage(Error.NOT_ARRAY_TYPE_IN_FOR_STATEMENT, {estr});
      then
        fail();
    // if-case
    case(env, Absyn.ALG_IF(ifExp = ae1,trueBranch = algitemlst,elseIfAlgorithmBranch = elseifexpitemlist, elseBranch = elseitemlist),ht2)
      equation
        trueBranch = (ae1,algitemlst);
        branches1 = (trueBranch :: elseifexpitemlist);
        branches2 = listAppend(branches1, {(Absyn.BOOL(true),elseitemlist)});
        env1 = evaluateIfStatementLst(branches2, env,ht2);
      then
        env1;
    // assert(true, ...) gives nothing!
    case(env, Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),
                                  functionArgs = Absyn.FUNCTIONARGS(args = {cond,msg})),ht2)
      equation
        (_,econd,_,_,_) = Static.elabExp(Env.emptyCache(), env, cond, true, NONE,true);
        (_,Values.BOOL(true),_) = Ceval.ceval(Env.emptyCache(),env, econd, true, NONE, NONE, Ceval.MSG());
      then
        env;
    // assert(false, ...) gives error!
    case(env, Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),
                                  functionArgs = Absyn.FUNCTIONARGS(args = {cond,msg})),ht2)
      equation
        (_,econd,_,_,_) = Static.elabExp(Env.emptyCache(), env, cond, true, NONE,true);
        (_,Values.BOOL(false),_) = Ceval.ceval(Env.emptyCache(),env, econd, true, NONE, NONE, Ceval.MSG());
        (_,e1,_,_,_) = Static.elabExp(Env.emptyCache(), env, msg, true, NONE,true);
        (_,Values.STRING(varName),_) = Ceval.ceval(Env.emptyCache(),env, e1, true, NONE, NONE, Ceval.MSG());
        Error.addMessage(Error.ASSERT_FAILED, {varName});
      then
        fail();
  end matchcontinue;
end evaluateAlgorithm;

protected function evaluateIfStatementLst "
  Evaluates all parts of a if statement (i.e. a list of exp  statements)"
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inIfs;
  input Env.Env env;
  input HashTable2.HashTable ht2;
  output Env.Env oenv;
algorithm oenv := matchcontinue(inIfs,env,ht2)
  local
      Values.Value value;
      Absyn.Exp ae1;
      list<Absyn.AlgorithmItem> algitemlst;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> algrest;
      Env.Env env1;

  case({},env,ht2) then env;
  case(((ae1,algitemlst)::algrest),env,ht2)
    equation
      value = evaluateSingleExpression(ae1,env,NONE,ht2);
      env1 = evaluatePartOfIfStatement(value, ae1, algitemlst, algrest, env,ht2);
    then 
      env1;
  end matchcontinue;
end evaluateIfStatementLst;

protected function evaluatePartOfIfStatement "function: evaluatePartOfIfStatement
  Evaluates one part of a if statement, i.e. one \"case\". If the condition is true, the algorithm items
  associated with this condition are evaluated. The first argument returned is set to true if the
  condition was evaluated to true. Fails if the value is not a boolean.
  Note that we are sending the expression as an value, so that it does not need to be evaluated twice."
  input Values.Value inValue;
  input Absyn.Exp inExp;
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTplAbsynExpAbsynAlgorithmItemLstLst;
  input Env.Env env;
  input HashTable2.HashTable ht2;
  output Env.Env oenv;
algorithm
  oenv := matchcontinue (inValue,inExp,inAbsynAlgorithmItemLst,inTplAbsynExpAbsynAlgorithmItemLstLst,env,ht2)
    local
      Env.Env env1;
      Boolean exp_val;
      list<Absyn.AlgorithmItem> algitemlst;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> algrest;
      String estr,tstr;
      tuple<DAE.TType, Option<Absyn.Path>> vtype;
      Values.Value value;
      Absyn.Exp exp;
      DAE.Exp daeExp;      

    // select if condition is true 
    case (Values.BOOL(boolean = true),_,algitemlst,_,env, ht2)
      equation
        env1 = evaluateConditionalStatement2(algitemlst, env, ht2);
      then
        env1;
    // select if condition is false
    case (Values.BOOL(boolean = false),_,algitemlst,algrest,env, ht2)
      equation
        env1 = evaluateIfStatementLst(algrest, env, ht2);
      then
        env1;
    // handle failure, report type error
    case (value,exp,algitemlst,algrest,env, ht2)  
      equation 
        (_,daeExp,_,_,_) = Static.elabExp(Env.emptyCache(),env,inExp,true,NONE,false); 
        estr = Exp.printExpStr(daeExp);
        vtype = Types.typeOfValue(value);
        tstr = Types.unparseType(vtype);
        Error.addMessage(Error.IF_CONDITION_TYPE_ERROR, {estr,tstr});
      then
        fail();
  end matchcontinue;
end evaluatePartOfIfStatement;

protected function evaluateSingleExpression "Function: evaluateSingleExpression
This function evaluates a single expression(mostly used in condition evaluation, for/while/if).
It also has an optional DAE.Type input if we want a specific type we will try to cast the input
to that type."
  input Absyn.Exp inExp "The Absyn Expression to evaluate";
  input Env.Env env "Current enviroment";
  input Option<DAE.Type> expectedType "SOME(DAE.Type) (convert into that type)";
  input HashTable2.HashTable ht2;
  output Values.Value oval;
algorithm oval := matchcontinue(inExp,env,expectedType,ht2)
  local 
    DAE.Exp e1,e2;
    Values.Value value;
    DAE.Type ty,ty2;

  // no type to convert into
  case(inExp,env,NONE,ht2)
    equation
      (_,e1,_,_,_) = Static.elabExp(Env.emptyCache(),env,inExp,true,NONE,false);
      e1 = replaceComplex(e1,ht2);
      (_,value,_) = Ceval.ceval(Env.emptyCache(),env, e1, true, NONE, NONE, Ceval.MSG());
    then
      value;
  // some type we need to convert into
  case(inExp,env,SOME(ty),ht2)
    equation
      (_,e1,DAE.PROP(ty2,_),_,_) = Static.elabExp(Env.emptyCache(),env,inExp,true,NONE,false);
      (e2,_) = Types.matchType(e1,ty2,ty,true);
      e2 = replaceComplex(e2,ht2);
      (_,value,_) = Ceval.ceval(Env.emptyCache(),env, e2, true, NONE, NONE, Ceval.MSG());
    then
      value;
  // failure
  case(_,_,_,_)
    equation
      Debug.fprint("failtrace", "- Cevalfunc.evaluateSingleExpression failed\n");
    then
      fail();
end matchcontinue;
end evaluateSingleExpression;

protected function evaluateForLoopArray "Function: evaluateForLoopArray
Evaluates a forloop while the for-values are in an array."
  input Env.Env env; 
  input String varName;
  input list<Values.Value> forValues;
  input list<Absyn.AlgorithmItem> statements;
  input HashTable2.HashTable ht2;
  output Env.Env oenv;
algorithm oenv:= matchcontinue(env,varName,forValues,statements,ht2)
  local
    list<Absyn.AlgorithmItem> statements;
    Values.Value value;
    list<Values.Value> values;
    Env.Env env1,env2,env3;

  case(env,_,{},_,_) then env;
  case(env,varName, value::values, statements,ht2)
    equation
      env1 = setValue(value,env,Absyn.CREF(Absyn.CREF_IDENT(varName,{})));
      env2 = evaluateConditionalStatement2(statements,env1, ht2);
      env3 = evaluateForLoopArray(env2,varName,values,statements, ht2);
    then
      env3;
end matchcontinue;
end evaluateForLoopArray;

protected function evaluateForLoopRange "Function: evaluateForLoopArray
Evaluates a forloop while the for-values are a range ex. 1:1:10."
  input Env.Env env;
  input String varName;
  input list<Absyn.AlgorithmItem> statements;
  input Values.Value start;
  input Values.Value step;
  input Values.Value stop;
  input HashTable2.HashTable ht2;
  output Env.Env oenv;
algorithm oenv:= matchcontinue(env,varName,statements,start,step,stop,ht2)
  local    
    list<Absyn.AlgorithmItem> statements;
    Values.Value newVal;
    list<Values.Value> values;
    Env.Env env1,env2,env3;

  case(env,varName,statements,start,step,stop,ht2) 
    equation
      true = ValuesUtil.safeLessEq(start,stop);
      env1 = setValue(start,env,Absyn.CREF(Absyn.CREF_IDENT(varName,{})));
      env2 = evaluateConditionalStatement2(statements,env1,ht2);
      newVal = ValuesUtil.safeIntRealOp(start,step,Values.ADDOP);
      env3 = evaluateForLoopRange(env2,varName,statements,newVal,step,stop,ht2);
    then
      env3;

  case(env,_,_,start,step,stop,ht2) 
    equation
      false = ValuesUtil.safeLessEq(start,stop);
    then env;
end matchcontinue;
end evaluateForLoopRange;

protected function evaluateConditionalStatement "Function: evaluateConditionalStatement
This function now only is used in while-loops.
It checks wheter the condition is true or false.
If true, evaluate body then update condition and call itself again.
"
  input Values.Value cond "Current condition, Values.( true/false)";
  input Absyn.Exp updateExp "The expression to generate next condition";
  input list<Absyn.AlgorithmItem> algitemlst "The statements in the body";
  input Env.Env env;
  input HashTable2.HashTable ht2;
  output Env.Env oenv;
algorithm oenv := matchcontinue(cond,updateExp,algitemlst,env,ht2)
  local
    Absyn.AlgorithmItem algi;
    list<Absyn.AlgorithmItem> algis;
    Env.Env env1,env2;
    Values.Value value, value2;
    DAE.Exp e1;
  case(Values.BOOL(false),_,_ ,env,ht2) then env;
  case(Values.BOOL(true), updateExp,algis,env,ht2)
    equation
      env1 = evaluateConditionalStatement2(algis,env,ht2);
      value2 = evaluateSingleExpression(updateExp,env1,NONE,ht2);
      env2 = evaluateConditionalStatement(value2,updateExp,algis,env1,ht2);
    then
      env2;
end matchcontinue;
end evaluateConditionalStatement;

protected function evaluateConditionalStatement2 "
A intermediate-function for evaluation algorithm statements.
"
input list<Absyn.AlgorithmItem> inalgs;
input Env.Env env;
input HashTable2.HashTable ht2;
output Env.Env oenv;
algorithm oenv := matchcontinue(inalgs,env,ht2)
  local
    Absyn.Algorithm alg;
    Env.Env env1,env2;
    list<Absyn.AlgorithmItem> rest;
  case({},env,ht2) then env;
  case(Absyn.ALGORITHMITEM(alg,_)::rest,env,ht2)
    equation
      env1 = evaluateAlgorithm(env,alg,ht2);
      env2 = evaluateConditionalStatement2(rest,env1,ht2);
      then
        env2;
  case(Absyn.ALGORITHMITEMANN(_)::rest,env,ht2)
    equation
      env1 = evaluateConditionalStatement2(rest,env,ht2);
    then
      env1;
end matchcontinue;
end evaluateConditionalStatement2;

protected function setValues "Function: setValues
This function set multiple(tuple) values.
"
  input list<Absyn.Exp> tupleCrefs;
  input list<DAE.Type> types;
  input list<Values.Value> varValues;
  input Env.Env env;
  output Env.Env oEnv;
algorithm oEnv := matchcontinue(tupleCrefs, types, varValues, env)
local
  Absyn.Exp cref;
  DAE.Type ty;
  Values.Value value;
  list<Absyn.Exp> crefs;
  list<DAE.Type> tys;
  list<Values.Value> values;
  Env.Env env1,env2;
  String str;
  list<Absyn.Subscript> subs;
  case({},{},{},env) then env;
  case(cref ::crefs, ty::tys, value::values, env)
    equation
      env1 = setValue(value,env,cref);
      env2 = setValues(crefs,tys,values,env1);
    then
        env2;
  case(_,_,_,_)
    equation
      Debug.fprint("failtrace", "- Cevalfunc.setValues failed\n");
      then fail();
end matchcontinue;
end setValues;

protected function setValue "Function: setValue
This function updates a generic-variable in the enviroment."
  input Values.Value inVal "new value for var";
  input Env.Env env "The enviroment the variable is in";
  input Absyn.Exp toAssign "The variable to assign";
  output Env.Env outVal;
algorithm outVal := matchcontinue(inVal,env,toAssign)
    local
      DAE.Type t;
      Env.Frame fr;      
      Env.Env env1,complexEnv;
      String str,str2,dbgString; 
      Values.Value value,value2;
      list<Absyn.Subscript> subs;      
      list<DAE.Var> typeslst,nlist;
      list<Values.Value> vals;
      list<String> names;        
      Absyn.ComponentRef child,dbgcr;
      Absyn.Exp me;
      DAE.ComponentRef eme;      

  // records
  case(value as Values.RECORD(_,vals,names,-1),env,Absyn.CREF(Absyn.CREF_IDENT(str,subs)))
    equation
      (_,_,t as (DAE.T_COMPLEX(_,typeslst,_,_),_),_,_,_,_) = Lookup.lookupVar(Env.emptyCache(),env, DAE.CREF_IDENT(str,DAE.ET_OTHER(),{}));
      nlist = setValuesInRecord(typeslst,names,vals);
      fr = Env.newFrame(false);
      complexEnv = makeComplexEnv({fr},nlist);
      // print("setValue -> component: " +& str +& " ty: " +& Types.printTypeStr(t) +& "\n");
      env1 = Env.updateFrameV(env,
          DAE.TYPES_VAR(str,DAE.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
            false,t,DAE.VALBOUND(value),NONE()), Env.VAR_TYPED(), complexEnv);
    then
      env1;
  // any other values with ident cref
  case(value,env,Absyn.CREF(Absyn.CREF_IDENT(str,subs)))
    equation
      (_,_,t,DAE.VALBOUND(value2),_,_,_) = Lookup.lookupVar(Env.emptyCache(),env, DAE.CREF_IDENT(str,DAE.ET_OTHER(),{}));
      value = mergeValues(value2,value,subs,env,t); 
      env1 = updateVarinEnv(env,str,value,t);
    then
      env1;
  // any other values with qualified cref
  case(value,env,me as Absyn.CREF(Absyn.CREF_QUAL(str,subs,child))) 
    equation 
      (_,_,t,DAE.VALBOUND(value2),_,_,_) = Lookup.lookupVar(Env.emptyCache(),env, DAE.CREF_IDENT(str,DAE.ET_OTHER(),{}));
      env1 = setQualValue(env,value,Absyn.CREF_QUAL(str,subs,child));
    then
      env1;
  // failure
  case(_,_,Absyn.CREF(dbgcr)) 
      equation
        true = RTOpts.debugFlag("failtrace");
        //(Absyn.CREF_IDENT(dbgString,_)) = Absyn.crefGetFirst(dbgcr);
        dbgString = Dump.printComponentRefStr(dbgcr);
        dbgString = Util.stringAppendList({"- Cevalfunc.setValue failed for ", dbgString,"\n"});
        Debug.fprint("failtrace", dbgString);
      then fail();
  end matchcontinue;
end setValue;

protected function addForLoopScope 
"Adds a scope in the environment used in for loops.
 adrpo NOTE:
   The variability of the iterator SHOULD
   be determined by the range constantness!"
  input Env.Env env;
  input String iterName;
  input Values.Value startValue;
  input SCode.Variability iterVariability;
  input Option<DAE.Const> constOfForIteratorRange;
  output Env.Env newEnv;
  DAE.Type baseType;
  Values.Value baseValue;
algorithm
  baseType := Types.typeOfValue(startValue);
  baseValue := typeOfValue(baseType);
  newEnv := Env.openScope(env, false, SOME(Env.forScopeName));
  newEnv := Env.extendFrameForIterator(newEnv, iterName, baseType, DAE.VALBOUND(baseValue), iterVariability, constOfForIteratorRange); 
end addForLoopScope;

protected function setQualValue "Function: setQualValue
This function sets the value of a qual complex var."
  input Env.Env env;
  input Values.Value inVal;
  input Absyn.ComponentRef inCr;
  output Env.Env oenv;
algorithm oenv := matchcontinue(env,inVal,inCr)
  local
    Env.Frame frame;
    list<Env.Frame> frames,newFrames;
    Option<String> farg1;
    Env.AvlTree farg2,farg22;
    Env.AvlTree farg3;
    list<Env.Item> farg4;
    tuple<list<DAE.ComponentRef>,DAE.ComponentRef> farg6;
    Boolean farg7;
    list<SCode.Element> defineUnits;    
    String str;
    Absyn.ComponentRef child;
    Integer hash;

  // try the first frame
  case( ( (frame as Env.FRAME(farg1, farg2, farg3, farg4, farg6, farg7,defineUnits) ) :: frames),inVal,inCr)    
    equation
      str = Absyn.crefFirstIdent(inCr);
      (_,_,_,_,_,_,_) = Lookup.lookupVar(Env.emptyCache(), {frame}, DAE.CREF_IDENT(str,DAE.ET_OTHER(),{}));
      farg22 = setQualValue2(farg2, inVal,inCr,0);
      then
        Env.FRAME(farg1,farg22,farg3,farg4,farg6,farg7,defineUnits) :: frames;    
  // try next frame
  case( frame :: frames, inVal,inCr ) // didn't find in this frame. 
    equation 
      newFrames = setQualValue(frames,inVal,inCr);
    then
      frame::newFrames;
  // failure
  case(_,_,_)
    equation
      Debug.fprint("failtrace", "- Cevalfunc.setQualValue failed\n");
      then fail();
  end matchcontinue;
end setQualValue;

protected function setQualValue2 "Function: setQualValue2
Helper function for setQualValue"
  input Env.AvlTree env;
  input Values.Value inVal;
  input Absyn.ComponentRef inCr;
  input Integer hashKey;
  output Env.AvlTree oenv;
algorithm oenv := matchcontinue(env,inVal,inCr ,hashKey)
  local
    String str;
    Absyn.ComponentRef child;
    Option<Env.AvlValue> otval;
    Env.AvlTreeValue tval,newtval;
    Option<Env.AvlTree> oleft, oright;
    Env.AvlTree left, right;
    Env.Ident rkey;
    Env.AvlValue rval;

    Integer rhval;
    DAE.Var fv;
    Option<tuple<SCode.Element, DAE.Mod>> c ;
    Env.InstStatus i;
    Env.Env varEnv,varEnv2;
    Integer h;

    case(Env.AVLTREENODE(SOME(Env.AVLTREEVALUE(rkey,rval as Env.VAR(fv,c,i,varEnv))),h,oleft,oright), inVal, inCr as Absyn.CREF_QUAL(str,_,child) ,hashKey)
      equation
        equality(rkey = str);
        true = Absyn.crefIsIdent(child);
        varEnv2 = setValue(inVal,varEnv,Absyn.CREF(child));
      then
        Env.AVLTREENODE(SOME(Env.AVLTREEVALUE(rkey,Env.VAR(fv,c,i,varEnv2))),h,oleft,oright);

    /*case(Env.AVLTREENODE(SOME(Env.AVLTREEVALUE(rkey,rval as Env.VAR(fv,c,i,varEnv))),h,oleft,oright), inVal, inCr as Absyn.CREF_QUAL(str,_,child) ,hashKey)
      equation
        equality(rkey = str);
        varEnv2 = setQualValue(varEnv,inVal,child);
        then
          Env.AVLTREENODE(SOME(Env.AVLTREEVALUE(rkey,Env.VAR(fv,c,i,varEnv2))),h,oleft,oright);
        // Check right
    case(Env.AVLTREENODE(SOME(Env.AVLTREEVALUE(rkey,rval)),h,oleft,SOME(right)), inVal, inCr ,hashKey)
      equation
        true = System.strcmp(key,rkey) > 0;
        right = setQualValue2(right,inVal,inCr,hashKey);
      then
        Env.AVLTREENODE(SOME(Env.AVLTREEVALUE(rkey,rval)),h,oleft,SOME(right));
        // Check left
    case(Env.AVLTREENODE(SOME(Env.AVLTREEVALUE(rkey,rval)),h,SOME(left),oright), inVal, inCr ,hashKey)
      equation
        true = System.strcmp(key,rkey) 0;
        rhval = Env.myhash(rkey);
        (hashKey < rhval) = true;
        left = setQualValue2(left,inVal,inCr,hashKey);
      then
        Env.AVLTREENODE(SOME(Env.AVLTREEVALUE(rkey,rval)),h,SOME(left),oright);
        */
  end matchcontinue;
end setQualValue2;

protected function updateVarinEnv "Function: updateVarinEnv
This function updates the current enviroment with the new value
on the identifier varName. If the variable is not there, extend 
the enviroment." 
  input Env.Env env "The variables enviroment";
  input String varName "The IDENT to update";
  input Values.Value newVal "The new value of the variable";
  input DAE.Type ty "Type of variable";
  output Env.Env outEnv "The new updated enviroment";
algorithm
  outEnv := matchcontinue(env,varName,newVal,ty)
    local
      Env.Env env1;
      DAE.Type t;

    case(env,varName,newVal,ty)
      equation
        (_,_,t,_,_,_,_) = Lookup.lookupVar(Env.emptyCache(), env,DAE.CREF_IDENT(varName,DAE.ET_OTHER(),{}));
        // print("updateVarinEnv -> component: " +& varName +& " ty: " +& Types.printTypeStr(ty) +& "\n");
        // print("updateVarinEnv -> component: " +& varName +& " ACTUAL ty: " +& Types.printTypeStr(t) +& "\n");
        env1 = Env.updateFrameV(env,
          DAE.TYPES_VAR(varName,DAE.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
            false,ty,DAE.VALBOUND(newVal),NONE()), Env.VAR_TYPED(), {}); 
      then
        env1;
    case(_,_,_,_) equation
      Debug.fprint("failtrace", "- Cevalfunc.updateVarinEnv failed\n");
      then fail();
  end matchcontinue;
end updateVarinEnv;

protected function makeBinding "Function: makeBinding
This function will evaluate possible mods(input) and if a bindingvalue is found it will
return a DAE.VALBOUND otherwise a DAE.UNBOUND
"
  input SCode.Mod inMod;
  input Env.Env env;
  input DAE.Type baseType;
  input HashTable2.HashTable ht2;
  output DAE.Binding outBind;
algorithm
  outBind :=
  matchcontinue(inMod,env,baseType, ht2)
    local
      tuple<Absyn.Exp,Boolean> absynExp;
      Absyn.Exp ae1;
      DAE.Exp e1;
      Values.Value value,value2,baseValue;
      DAE.Type ty;
    case(SCode.MOD(absynExpOption = SOME(absynExp), eachPrefix = Absyn.NON_EACH) ,env,ty , ht2)
      equation
        ae1 = Util.tuple21(absynExp);
        value = evaluateSingleExpression(ae1,env,SOME(ty), ht2);
      then
        DAE.VALBOUND(value);
    case(SCode.MOD(absynExpOption = SOME(absynExp), eachPrefix = Absyn.EACH) ,env,ty , ht2)
      equation
        ae1 = Util.tuple21(absynExp);
        value = evaluateSingleExpression(ae1,env,SOME(ty), ht2);
        value2 = instFunctionArray(ty,SOME(value));
      then
        DAE.VALBOUND(value2);
    case(SCode.MOD(absynExpOption = NONE),_,ty, ht2)
      equation
        baseValue = instFunctionArray(ty,NONE);
      then
        DAE.VALBOUND(baseValue);
    case(SCode.NOMOD,_,ty, ht2)
      equation
        baseValue = instFunctionArray(ty,NONE);
      then
        DAE.VALBOUND(baseValue);
    case(SCode.MOD(absynExpOption = SOME(absynExp)),_,_, ht2)
      equation
        Debug.fprint("failtrace", "- Cevalfunc.makeBinding failed not fully implemented\n");
      then
        fail();
  end matchcontinue;
end makeBinding;

protected function instFunctionArray "Function: instFunctionArray
This function will instantiate the array in the env.
If a 2x2 matrix, it will generate a 2x2 matrix of zeroes. This is to get the env lookup to work.
"
input DAE.Type inType;
input Option<Values.Value> optVal;
output Values.Value outArrOfZeroes;

algorithm
  outArrOfZeroes :=
  matchcontinue(inType,optVal)
      local
        DAE.Type ty,ty2,bt;
        DAE.ArrayDim ad;
        Values.Value val;
        list<Integer> dims,dims2;
    case(ty,optVal) // array
      equation
        (bt,dims) = Types.flattenArrayType(ty);
        dims2 = listReverse(dims);
        false = (listLength(dims) ==0);
        val = instFunctionArray2(dims2,bt,optVal);
        then
          val;
    case(ty,_) // non-array have this to skip another function
      equation
        (bt,dims) = Types.flattenArrayType(ty);
        true = (listLength(dims) == 0);
        val = typeOfValue(ty);
      then
        val;
  end matchcontinue;
end instFunctionArray;

protected function instFunctionArray2 "Function: instFunctionArray
This function will instantiate the array in the env.
If a 2x2 matrix, it will generate a 2x2 matrix of zeroes. This is to get the env lookup to work.
"
input list<Integer> inDims;
input DAE.Type inType;
input Option<Values.Value> optVal;
output Values.Value outArrOfZeroes;

algorithm
  outArrOfZeroes :=
  matchcontinue(inDims,inType,optVal)
      local
        DAE.Type ty,ty2,bt;
        DAE.ArrayDim ad;
        Values.Value value,val;
        list<Values.Value> values;
        Integer dim;
        list<Integer> dims;

    case(dim :: dims, ty ,optVal)
      equation
        true = (listLength(inDims)>0);
        value = instFunctionArray2(dims, ty,optVal);
        values = Util.listFill(value,dim);
        value = Values.ARRAY(values, dim::dims);
        then
          value;
    case({}, ty , SOME(value))
      then
        value;
    case({}, ty , NONE)
      equation
        value = typeOfValue(ty);
      then
      value;
  end matchcontinue;
end instFunctionArray2;

protected function typeOfValue ""
input DAE.Type inType;
output Values.Value oval;
algorithm oval := matchcontinue(inType)
  local     Absyn.Path path;
  case((DAE.T_INTEGER(_),_)) then Values.INTEGER(0);
  case((DAE.T_REAL(_),_)) then Values.REAL(0.0);
  case((DAE.T_STRING(_),_)) then Values.STRING("");
  case((DAE.T_BOOL(_),_)) then Values.BOOL(false);
  case((DAE.T_ENUMERATION(SOME(idx),path,names,_),_))
    local
      Integer idx;
      list<String> names;
    then Values.ENUM(idx,path,names);
//       then Values.ENUM(DAE.CREF_IDENT("",Exp.ENUM(),{}),0);
//  case((DAE.T_ENUM,_)) then Values.ENUM(DAE.CREF_IDENT("",Exp.ENUM(),{}),0);
  case((DAE.T_COMPLEX(ClassInf.RECORD(path), typesVar,_,_),_))
    local
      list<DAE.Var> typesVar;
    equation

      then
        Values.RECORD(path,{},{},-1) ;
  case(_)
    equation
      Debug.fprint("failtrace", "- Cevalfunc.typeOfValue failed might not be complete implemented\n");
      then fail();
  /*
  record TUPLE
    list<Value> valueLst;
  end TUPLE;

  record RECORD
    Absyn.Path record_ "record name" ;
    list<Value> orderd "orderd set of values" ;
    list<DAE.Ident> comp "comp names for each value" ;
  end RECORD;
  */
end matchcontinue;
end typeOfValue;

protected function getTypeFromName "function: getTypeFromName
  Returns the type specified by the path.
"
  input Absyn.Path inPath;
  input Env.Env env;
  output DAE.Type outType;
algorithm
  outType:=
  matchcontinue (inPath,env)
    local
      DAE.Type ty;
      list<Integer> dims;
      String typeName,className;
      Absyn.Path rest,p;
      SCode.Class typeClass;
      Env.Env env1,env2;
      list<Inst.DimExp> dims;

    case (Absyn.IDENT(typeName),env)
      equation
        ty = getBuiltInTypeFromName(typeName);
        then
          ty;
    case(Absyn.FULLYQUALIFIED(p),env)
      equation
        ty = getTypeFromName(p,env);
      then
        ty;
    case(p ,env)
      equation        
        (_,typeClass as SCode.CLASS(name=className),env1) = Lookup.lookupClass(Env.emptyCache(), env, p, false);
        (_,dims,typeClass,_,_) = Inst.getUsertypeDimensions(Env.emptyCache(), env1, DAE.NOMOD(), Prefix.NOPRE(), typeClass, {}, true);
        (_,env2,_,_,_,_,ty,_,_,_) = Inst.instClass(
          Env.emptyCache(),env1,InnerOuter.emptyInstHierarchy,UnitAbsyn.noStore,DAE.NOMOD(),Prefix.NOPRE(),Connect.emptySet,typeClass,{}, true, Inst.INNER_CALL, ConnectionGraph.EMPTY);
        ty = Inst.makeArrayType(dims, ty);
      then
        ty;
    case (_,_)
      equation
        Debug.fprint("failtrace", "- Cevalfunc.getTypeFromName failed, unmatched type\n");
        then fail();
  end matchcontinue;
end getTypeFromName;

protected function getBuiltInTypeFromName "function: getTypeFromName
  Returns the type from a string-name
"
  input String inString;
  output DAE.Type outType;
algorithm
  outType:=
  matchcontinue (inString)
    local
      String nonBuiltin;
      SCode.Class typeClass;
    case ("Integer") then DAE.T_INTEGER_DEFAULT;
    case ("Real") then DAE.T_REAL_DEFAULT;
    case ("String") then DAE.T_STRING_DEFAULT;
    case ("Boolean") then DAE.T_BOOL_DEFAULT;

  end matchcontinue;
end getBuiltInTypeFromName;


protected function getOutputVarValues "Function: getOutPutVarValues
This function get the output variables and looks them up in the env.
NOTE: now we only return one value to fit Ceval.mo
"
input list<SCode.Element> elements;
input Env.Env env;
output list<Values.Value> res;
algorithm
  res :=
  matchcontinue(elements,env)
      local
        list<SCode.Element> eles1;
        SCode.Element ele1;
        list<Values.Value> lval;
        Values.Value value;
        String varName;
    case({},_) then {};
    case(((ele1 as SCode.COMPONENT(component = varName, attributes = SCode.ATTR(direction = Absyn.OUTPUT() ) ))::eles1),env)
      equation
        (_,_,_,DAE.VALBOUND(value),_,_,_) = Lookup.lookupVar(Env.emptyCache(),env, DAE.CREF_IDENT(varName,DAE.ET_OTHER(),{}));
        lval = getOutputVarValues(eles1,env);
      then
       value::lval;
     /*TODO: Handle extends nodes, must pick up output arguments from base classes */
    case(_::eles1,env)
      equation
        lval = getOutputVarValues(eles1,env);
      then
        lval;
  end matchcontinue;
end getOutputVarValues;

protected function convertOutputVarValues "Function: convertOutputVarValues
This function converts a list of values to a tuple value (if list contains more than one value) "
input list<Values.Value> indata;
output Values.Value outdata;
algorithm outdata := matchcontinue(indata)
  local
    Values.Value retVal;
  case(indata)
    equation
      true = (listLength(indata) == 1);
      retVal = listNth(indata,0);
      then
        retVal;
  case(indata) /* length > 1 */ then Values.TUPLE(indata);
end matchcontinue;
end convertOutputVarValues;

protected function mergeValues "Function: mergeValues
This function will update a specific value location.
"
input Values.Value oldVal "This is the old value, to update inside";
input Values.Value newVal "This is the new value, which we will insert into returning Value";
input list<Absyn.Subscript> insubs;
input Env.Env env;
input DAE.Type ty;
output Values.Value oval;
algorithm oval := matchcontinue(oldVal,newVal,insubs,env,ty)
  local
    Absyn.Subscript sub;
    list<Absyn.Subscript> subs;
    Values.Value value,val1,val2,val3;
    list<Values.Value> values1,values2,values3,values4;
    DAE.Exp e1;
    Integer x;
    Absyn.Exp exp;
    list<Integer> dims;
    case(_,newVal,{},_,ty)
      equation
        (ty,_) = Types.flattenArrayType(ty);
        value = checkValueTypes(newVal,ty);
        then value;

  case((oldVal as Values.ARRAY(valueLst = values1, dimLst = dims)),newVal,((sub as Absyn.SUBSCRIPT(exp))::subs),env,ty)
    equation
      (_,e1,_,_,_) = Static.elabExp(Env.emptyCache(),env,exp,true,NONE,false);
      (_,value as Values.INTEGER(x),_) = Ceval.ceval(Env.emptyCache(),env, e1, true, NONE, NONE, Ceval.MSG());
      val1 = listNth(values1 ,(x-1)); // to be replaced
      val2 = mergeValues(val1,newVal,subs,env,ty);
      values2 = Util.listReplaceAt(val2,(x-1),values1);
      val3 = Values.ARRAY(values2,dims);
    then
      val3;
  case((oldVal as Values.ARRAY(valueLst = values1, dimLst = dims)),(newVal as Values.ARRAY(valueLst = values2)),((sub as Absyn.NOSUB)::subs),env,ty)
    equation
      values3 = mergeValues2(values1,values2,subs,env,ty);
      val3 = Values.ARRAY(values3,dims);
    then
      val3;
  end matchcontinue;
end mergeValues;

protected function mergeValues2 ""
input list<Values.Value> oldVal;
input list<Values.Value> newVal;
input list<Absyn.Subscript> insubs;
input Env.Env env;
input DAE.Type ty;
output list<Values.Value> oval;
algorithm oval := matchcontinue(oldVal,newVal,insubs,env,ty)
  local
    Values.Value val1,val2,val3;
    list<Values.Value> vals1,vals2,vals3;
    case({},{},_,_,_) then {};
    case(val1::vals1, val2::vals2, insubs,env,ty)
      equation
        val3 = mergeValues(val1,val2,insubs,env,ty);
        vals3 = mergeValues2(vals2,vals2,insubs,env,ty);
        then
          val3::vals3;
end matchcontinue;
end mergeValues2;

protected function checkValueTypes "
This function takes a Values.Value and a DAE.Type
Checks if the Value corresponds to the type.
If value is a Integer and Type is Real, it it converted to a real Value.
"
input Values.Value val;
input DAE.Type ty;
output Values.Value outVal;
algorithm outVal := matchcontinue(val,ty)
  local
    list<Values.Value> vals1,vals2;
    Values.Value val1,val2;
    list<Integer> dims;
    Integer ix;
    Real rx;
  case(Values.ARRAY(vals1,dims), ty as (DAE.T_REAL(_),_))
    equation
      vals2 = Util.listMap1(vals1,checkValueTypes,ty) ;
      val1 = Values.ARRAY(vals2,dims);
    then
      val1;
  case(Values.ARRAY(vals1,dims), ty as (DAE.T_INTEGER(_),_))
    equation
      vals2 = Util.listMap1(vals1,checkValueTypes,ty);
      val1 = Values.ARRAY(vals2,dims);
    then
      val1;
  case(Values.INTEGER(ix), ty as (DAE.T_REAL(_),_))
    equation
    rx = intReal(ix);
      then
        Values.REAL(rx);
  case(Values.REAL(rx), ty as (DAE.T_INTEGER(_),_))
    equation
    ix = realInt(rx);
    //print("WARNING unsafe conversion from real to integer\n");
      then
        Values.INTEGER(ix);
  case(val1,_) then val1; // normal case
end matchcontinue;
end checkValueTypes;

protected function addDims "Function: addDims
This function adds the dimensions to the variable
"
  input DAE.Type ty "The raw type";
  input Absyn.ArrayDim arrayDim "The dimensions to add";
  input Env.Env env "Variables enviroment";
  input HashTable2.HashTable ht2;
  output DAE.Type outType "resulting type";
algorithm outType := matchcontinue(ty,arrayDim,env,ht2)
  local
    Absyn.Subscript sub1;
    list<Absyn.Subscript> subs1;
    Absyn.Exp exp;
    Integer x;
    Values.Value val;
  case(ty,{},_,ht2) then ty;
  case(ty, (sub1 as Absyn.SUBSCRIPT(exp))::subs1,env,ht2)
    equation
      (val as Values.INTEGER(x)) = evaluateSingleExpression(exp,env,NONE,ht2);
      ty = Types.liftArrayRight(ty,SOME(x));
      ty = addDims(ty,subs1,env,ht2);
    then
      ty;
end matchcontinue;
end addDims;

protected function createReplacementRules "
Author BZ
Create a list replacement rules, mapping a variable (component reference) to its value (represented as Exp.Exp)
"
  input list<Values.Value> vals;
  input list<SCode.Element> elems;
  output list<tuple<DAE.ComponentRef, DAE.Exp>> res;
algorithm res := matchcontinue(vals,elems)
  local
    SCode.Element e;
    Values.Value v;
    String s1;
    list<Values.Value> rvals;
    list<String> rcomps;
    list<tuple<DAE.ComponentRef, DAE.Exp>> res1,res2;
  case({},_) then {};
  case(Values.RECORD(orderd=rvals, comp=rcomps)::vals,(e as SCode.COMPONENT(component=s1))::elems)
    equation
      res1 = createReplacementRulesRecord(DAE.CREF_IDENT(s1,DAE.ET_OTHER,{}),rvals,rcomps);
      res2 = createReplacementRules(vals,elems);
      res = listAppend(res1,res2);
    then
      res;
  case(v::vals,e::elems)
    equation
      res = createReplacementRules(vals,elems);
    then
      res;
end matchcontinue;
end createReplacementRules;

protected function createReplacementRulesRecord "
Author BZ
Helper function for createReplacementRules
"
input DAE.ComponentRef inRef;
input list<Values.Value> vals;
input list<String> comps;
  output list<tuple<DAE.ComponentRef, DAE.Exp>> res;
algorithm
  res := matchcontinue(inRef,vals,comps)
  local
    Values.Value v;
    String c;
    DAE.ComponentRef cref;
    list<tuple<DAE.ComponentRef, DAE.Exp>> res1,res2;
    case(_,{},_) then {};
    case(inRef,v::vals,c::comps)
      equation
        cref = Exp.extendCref(inRef,DAE.ET_OTHER,c,{});
        res1 = createReplacementRulesRecord2(v,cref);
        res2 = createReplacementRulesRecord(inRef,vals,comps);
        res = listAppend(res1,res2);
        then
          res;
  end matchcontinue;
end createReplacementRulesRecord;

protected function createReplacementRulesRecord2 "
Author BZ
Helper function for createReplacementRules
"
  input Values.Value v;
  input DAE.ComponentRef inRef;
  output list<tuple<DAE.ComponentRef, DAE.Exp>> res;
algorithm res := matchcontinue(v,inRef)
  local
    list<Values.Value> vals;
    list<String> comps;
    Integer i;
    Real r;
    Boolean b;
    String str;
  case(Values.ARRAY(valueLst = vals),inRef)
    equation
      res = createReplacementRulesRecordArray(vals,{},inRef,0);
    then
      res;
  case(Values.RECORD(orderd=vals,comp=comps),inRef)
    equation
      res = createReplacementRulesRecord(inRef,vals,comps);
    then
      res;
  case(Values.INTEGER(i),inRef)
    equation
    then {(inRef,DAE.ICONST(i))};
  case(Values.REAL(r),inRef)
    equation
    then {(inRef,DAE.RCONST(r))};
  case(Values.STRING(str),inRef)
    equation
    then {(inRef,DAE.SCONST(str))};
  case(Values.BOOL(b),inRef)
    equation
    then {(inRef,DAE.BCONST(b))};
end matchcontinue;
end createReplacementRulesRecord2;

protected function createReplacementRulesRecordArray "
Author BZ
Helper function for createReplacementRules
"
input list<Values.Value> inVals;
input list<DAE.Subscript> subs;
input DAE.ComponentRef inCref;
input Integer offset;
  output list<tuple<DAE.ComponentRef, DAE.Exp>> res;
algorithm res := matchcontinue(inVals,subs,inCref,offset)
  local
    list<Values.Value> vals1,vals2;
    Values.Value v;
    list<String> comps;
    list<tuple<DAE.ComponentRef, DAE.Exp>> res1,res2;
    DAE.ComponentRef cref;
  case({},_,_,_) then {};
  case(Values.ARRAY(valueLst = {})::{},_,_,_) then {};
  case((v as Values.ARRAY(valueLst = vals2))::vals1,subs,inCref,offset)
    equation
      offset=offset+1;
      res2 = createReplacementRulesRecordArray(vals1,subs,inCref,offset);
      subs = listAppend(subs,{DAE.INDEX(DAE.ICONST(offset))});
      res1 = createReplacementRulesRecordArray(vals2,subs,inCref,0); // next dim
      res = listAppend(res1,res2);
    then
      res;
  case(v::vals1,subs,inCref,offset)
    local
      String subsString;
    equation
      offset=offset+1;
      res1 = createReplacementRulesRecordArray(vals1,subs,inCref,offset);
      false = ValuesUtil.isArray(v);
      subs = listAppend(subs,{DAE.INDEX(DAE.ICONST(offset))});
      inCref = Exp.subscriptCref(inCref,subs);
      res2 = createReplacementRulesRecord2(v,inCref);
      res = listAppend(res1,res2);
    then
      res;
end matchcontinue;
end createReplacementRulesRecordArray;

end Cevalfunc;
