package Cevalfunc "
    Copyright (C) MathCore Engineering AB, 2007
 
 
 Author: Bjorn Zachrisson 

  
  file:	 Cevalfunc.mo
  module:      MATHCORE
  description: This module constant evaluates userdefined functions, speeds up instantination process.
  It includes 
  Constant evaluations of function and algorithm statements.
  RCS: $Id: Cevalfunc.mo 3059 2008-05-15 07:03:53Z bjozac $
"
public import Env;
public import Exp;
public import Values; 
public import Absyn;
public import Types;
public import DAE;
public import SCode; 
public import Prefix;
public import Connect;
public import ClassInf;
public import ConnectionGraph;

protected import Ceval;
protected import Util;
protected import Error;
protected import Debug;
protected import Lookup;
protected import Static;
protected import Inst;

protected constant String forScopeName="$for loop scope$";

public function cevalUserFunc "Function: cevalUserFunc
This is the main funciton for the class. It will take a userdefined function and \"try\" to
evaluate it. This is to prevent multiple compilation of c files.
"
  input Env.Env env "enviroment for the user-function";
  input Exp.Exp callExp "Exp.CALL(userFunc)"; 
  input list<Values.Value> inArgs; 
  input SCode.Class sc; 
  input list<DAE.Element> daeList;
  output Values.Value outVal "The output value"; 
  
algorithm
  outVal := 
  matchcontinue(env,callExp,inArgs,sc,daeList) 
      local 
        list<SCode.Element> elementList;
        Env.Env env1,env2,env3;
        Values.Value retVal;
        list<Values.Value> retVals;
        Absyn.Path funcpath;
        list<Exp.Exp> crefArgs;
        String str;
    case(env,(callExp as Exp.CALL(path = funcpath,expLst = crefArgs)),inArgs, sc as SCode.CLASS(_,false,_,SCode.R_FUNCTION(),SCode.PARTS(elementList,_,_,_,_,_) ),daeList)
      equation
        str = Absyn.pathString(funcpath);
        str = Util.stringAppendList({"cevalfunc_",str});
        env3 = Env.openScope(env, false, SOME(str));
        env1 = extendEnvWithInputArgs(env3,elementList,inArgs,crefArgs);
        env2 = evaluateStatements(env1,sc);
        retVals = getOutputVarValues(elementList, env2);
        retVal = convertOutputVarValues(retVals); 
        then 
          retVal;
    case(env,(callExp as Exp.CALL(path = funcpath,expLst = crefArgs)),inArgs, sc as SCode.CLASS(_,false,_,SCode.R_FUNCTION(),SCode.PARTS(elementList,_,_,_,_,_) ),daeList)
      equation
        _ = extendEnvWithInputArgs(env,elementList,inArgs,crefArgs);
        str = Absyn.pathString(funcpath);
        str = Util.stringAppendList({"- Cevalfunc.evaluateStatements failed for function /* ",str," */\n"});
        Debug.fprint("failtrace", str);
        then
          fail();
    case(env,(callExp as Exp.CALL(path = funcpath,expLst = crefArgs)),inArgs, sc as SCode.CLASS(_,false,_,SCode.R_FUNCTION(),SCode.PARTS(elementList,_,_,_,_,_) ),daeList)
      equation        
        failure(_ = extendEnvWithInputArgs(env,elementList,inArgs,crefArgs));
        str = Absyn.pathString(funcpath);
        str = Util.stringAppendList({"- Cevalfunc.extendEnvWithInputArgs failed for function /* ",str," */"});
        Debug.fprint("failtrace", str);
      then
        fail();
  end matchcontinue;
end cevalUserFunc;

protected function extendEnvWithInputArgs "Function: extendEnvWithInputArgs
This function will extend the current functions enviroment with the input argument(/s) 
and thier evaluated value. 
" 
  input Env.Env env;
  input list<SCode.Element> functionElements;
  input list<Values.Value> elementValues;
  input list<Exp.Exp> crefArgs;
  output Env.Env envOut;
algorithm 
  envOut := 
  matchcontinue(env, functionElements, elementValues, crefArgs)
    local 
      SCode.Element ele1;
      list<SCode.Element> eles1;
      SCode.Mod mod1;
      Values.Value val1;
      list<Values.Value> vals1;
      Env.Env env1,env2,complexEnv;
      String varName, str;
      Types.Var tvar;
      Types.Attributes tattr;
      Types.Type ty,tty;
      Types.Binding binding,tb;
      Exp.Type ety;
      Exp.Exp e1;
      list<Exp.Exp> restExps;      
      Absyn.ArrayDim adim;
      Absyn.ComponentRef cr;
      Absyn.Path apath;
      ClassInf.State recordconst; // for complex env construction
      list<Types.Var> typeslst;
      Option<Types.Type> cto; // for complex env construction, to here
    case(env,{},_,_) then env;
    case(env, (ele1 as SCode.EXTENDS(_,_))::eles1, vals1,restExps)
      equation
        env1 = extendEnvWithInputArgs(env,eles1,vals1,restExps);
        then
          env1;          
    case(env, ((ele1 as SCode.COMPONENT(component = varName, typeSpec = Absyn.TPATH(path = apath), modifications=mod1, attributes = SCode.ATTR(direction = Absyn.INPUT() ) ))::eles1), (val1::vals1),((e1 as Exp.CALL(path = _))::restExps))
      equation
        (tty as (Types.T_COMPLEX(recordconst,typeslst,cto,_),_)) = makeComplexForEnv(e1, val1); //Types.expTypetoTypesType(ety);
        complexEnv = Env.newFrame(false); 
        complexEnv = makeComplexEnv({complexEnv},typeslst);
        env1 = Env.extendFrameV(env,
          Types.VAR(varName,Types.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
            false,tty,Types.VALBOUND(val1)), NONE, Env.VAR_TYPED(), complexEnv);
        env2 = extendEnvWithInputArgs(env1,eles1,vals1,restExps);
      then
        env2;
    case(env, ((ele1 as SCode.COMPONENT(component = varName, typeSpec = Absyn.TPATH(path = apath), modifications=mod1, attributes = SCode.ATTR(direction = Absyn.INPUT() ,arrayDims=adim) ))::eles1), (val1::vals1),((e1)::restExps))
      equation
        tty = Types.typeOfValue(val1);
        env1 = Env.extendFrameV(env,
          Types.VAR(varName,Types.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
            false,tty,Types.VALBOUND(val1)), NONE, Env.VAR_TYPED(), {});
        env2 = extendEnvWithInputArgs(env1,eles1,vals1,restExps);
      then
        env2;
    case(_, ((ele1 as SCode.COMPONENT(component = varName, typeSpec = Absyn.TPATH(path = apath), attributes = SCode.ATTR(direction = Absyn.INPUT() ) ))::_), _,_)
      equation
        Debug.fprint("failtrace", "- Cevalfunc.extendEnvWithInputArgs with input variable failed\n");
      then 
        fail();
        /******************* INPUT ARGS ENDS ***********************/
        /***********************************************************/
        /*************** FUNCTION VARIABLE BEGINS ******************/
    case(env, ((ele1 as SCode.COMPONENT(component=varName,attributes = SCode.ATTR(arrayDims=adim, direction = Absyn.BIDIR()), typeSpec = Absyn.TPATH(path = apath), modifications = mod1)) ::eles1), (vals1),restExps)
      equation
        (tty as (Types.T_COMPLEX(_,typeslst,_,_),_) )= getTypeFromName(apath,env);
        binding = makeBinding(mod1,env,tty); 
        env1 = Env.extendFrameV(env, 
          Types.VAR(varName,Types.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
            false,tty,binding), NONE, Env.VAR_TYPED(), {});
        env2 = extendEnvWithInputArgs(env1,eles1,vals1,restExps);
      then
        env2;
        
    case(env, ((ele1 as SCode.COMPONENT(component=varName,attributes = SCode.ATTR(arrayDims=adim), typeSpec = Absyn.TPATH(path = apath), modifications = mod1)) ::eles1), (vals1),restExps)
      local Values.Value vv;
      equation
        tty = getTypeFromName(apath,env);
        tty = addDims(tty,adim,env);
        (binding as Types.VALBOUND(vv)) = makeBinding(mod1,env,tty); 
        env1 = Env.extendFrameV(env, 
          Types.VAR(varName,Types.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
            false,tty,binding), NONE, Env.VAR_TYPED(), {});
        env2 = extendEnvWithInputArgs(env1,eles1,vals1,restExps);
      then
        env2;
    case(env, (_::eles1), (vals1),restExps)
      equation
        //print(" FAILURE !!!! \n"); 
        //env1 = extendEnvWithInputArgs(env,eles1,vals1,restExps);
      then
        fail();//env1;
  end matchcontinue;
end extendEnvWithInputArgs;

protected function makeComplexForEnv "Function: makeComplexForEnv 
Special case for complex structure
"
  input Exp.Exp inExp "The call statement";
  input Values.Value inVal "Values.RECORD";
  output Types.Type oType;
algorithm (oType) := matchcontinue(inExp, inVal)
  local
    Absyn.Path recordName;
    Exp.Type ty;
    Types.Type cty,cty2;
    list<Types.Var> lv,lv2;
    String pathName;
    list<Values.Value> vals;
    list<String> names;
  case(Exp.CALL(recordName,_,_,_,ty), inVal as Values.RECORD(_,vals,names ))
    equation
      pathName = Absyn.pathString(recordName);
      (cty as (Types.T_COMPLEX(_,lv,_,_),_)) = Types.expTypetoTypesType(ty);
      lv2 = setValuesInRecord(lv,names,vals);
      cty2 = (Types.T_COMPLEX(ClassInf.RECORD(pathName) ,lv2 , NONE, NONE),NONE); 
    then
      cty2;
end matchcontinue;
end makeComplexForEnv;

protected function setValuesInRecord "Function: setValuesInRecord 
This function sets Values in records. 
"
input list<Types.Var> inVars;  
input list<String> invarNames; // eq 
input list<Values.Value> inValue; // eq
output list<Types.Var> oType;
algorithm oType := matchcontinue(inVars,invarNames,inValue)
  local 
    String varName;
    list<String> varNames;
    Types.Attributes a ;
    Boolean p ;
    Types.Type t ;
    Types.Binding b;
    Values.Value val;
    list<Values.Value> values;
    Types.Var tv,tv1;
    list<Types.Var> tvs,rest;
  case({},_,_) then {};
  case( tv1 :: rest , varName::varNames, val::values)
    equation
      tv = setValuesInRecord2(tv1,(varName::varNames),(val::values));
      tvs = setValuesInRecord(rest,varNames,values);
    then tv::tvs;
      end matchcontinue;
end setValuesInRecord;

protected function setValuesInRecord2 "Function: setValuesInRecord2
helper function for setValuesInRecord 
"
input Types.Var inVars; 
input list<String> invarName; // eq 
input list<Values.Value> inValue; // eq
output Types.Var oType;
algorithm oType := matchcontinue(inVars,invarName,inValue)
  local 
    String varName3,varName2;
    list<String> varNames;
    Types.Attributes a;
    Boolean p;
    Types.Type t,ty2;
    Types.Binding b;
    Values.Value val;
    list<Values.Value> values;
    Types.Var tv,tv1;
    list<Types.Var> tvs,rest;
  case(Types.VAR(varName2,a,p,t,Types.UNBOUND),{},{})
    equation
      val = typeOfValue(t);
      tv = Types.VAR(varName2,a,p,t,Types.VALBOUND(val));
    then
      tv;
  case((tv as Types.VAR(varName2,a,p,t,Types.VALBOUND(val))),{},{})
    then
      tv;
  case(Types.VAR(varName3,a,p, (t as (Types.T_COMPLEX(complexVarLst = typeslst),_)) ,b) ,varName2::varNames, (val as Values.RECORD(_,vals,names ))::values)
    local
      list<Types.Var> typeslst,lv2;
      list<Values.Value> vals;
      list<String> names;
    equation 
      equality(varName3 = varName2);
      lv2 = setValuesInRecord(typeslst,names,vals);
      ty2 = (Types.T_COMPLEX(ClassInf.RECORD(varName2) ,lv2 , NONE, NONE),NONE);
      tv = Types.VAR(varName3,a,p,ty2,Types.VALBOUND(val));
    then tv;
  case(Types.VAR(varName3,a,p,t,b) ,varName2::varNames, val::values)
    equation 
      equality(varName3 = varName2);
      tv = Types.VAR(varName3,a,p,t,Types.VALBOUND(val));
    then tv;      
  case(tv1,varName3::varNames, val::values)
    equation
      tv = setValuesInRecord2(tv1,varNames,values);
    then tv;
end matchcontinue;
end setValuesInRecord2;

protected function makeComplexEnv "Function: makeComplexEnv
This function extends the env with a complex var. 
"
input Env.Env env;
input list<Types.Var> tvars; 
output Env.Env oenv; 
algorithm oenv := matchcontinue(env, tvars)
local 
  ClassInf.State recordconst;
  list<Types.Var> typeslst;
  Option<Types.Type> cto;
  String name;// matching
  Types.Attributes attr;
  Boolean prot;
  Types.Type ty;
  Types.Binding bind;  
  Values.Value val;
  list<Types.Var> vars;// matching end 
  Types.Var tv;
  Env.Env env1,env2,complexEnv;
  case(env,{}) then env;
  case(env, (tv as Types.VAR(name,attr,prot,ty,bind ))::vars)
    equation
      Types.simpleType(ty);
      env1 = Env.extendFrameV(env, tv, NONE, Env.VAR_TYPED(), {});
      env2 = makeComplexEnv(env1, vars);
      then 
        env2;
  case(env, (tv as Types.VAR(name,attr,prot,(ty as (Types.T_COMPLEX(_,typeslst,_,_),_)) , _))::vars)
    equation
       complexEnv = Env.newFrame(false); 
       complexEnv = makeComplexEnv({complexEnv},typeslst);
        env1 = Env.extendFrameV(env,
        Types.VAR(name,Types.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
        false,ty,Types.UNBOUND), NONE, Env.VAR_TYPED(), complexEnv);
      env2 = makeComplexEnv(env1, vars);
      then 
        env2;
      case(_,_) 
        equation 
        Debug.fprint("failtrace", "- Cevalfunc.makeComplexEnv failed\n");
        then fail();
end matchcontinue;
end makeComplexEnv; 

protected function evaluateStatements "Function: evaluateStatements
Intermediate step for evaluating algorithms. 
"
  input Env.Env env;
  input SCode.Class sc; 
  output Env.Env outVal;
algorithm outVal := matchcontinue(env,sc)
  local 
    list<SCode.Equation> eqs1,eqs2;
    list<SCode.Algorithm> algs1,algs2;
    Env.Env env1;
  case(env, SCode.CLASS(_,false,_,SCode.R_FUNCTION(),SCode.PARTS(_,eqs1,eqs2,algs1,algs2,_)) )
    equation
      env1 = evaluateAlgorithmsList(env,algs1);
    then
      env1;
end matchcontinue;
end evaluateStatements;

protected function evaluateAlgorithmsList "Function: evaluateAlgorithms 
Intermediate step for evaluating algorithms. 
"
  input Env.Env env;
  input list<SCode.Algorithm> inAlgs;
  output Env.Env outEnv;
algorithm outEnv := matchcontinue(env,inAlgs)
  local
    list<SCode.Algorithm> algs;
    SCode.Algorithm alg;
    list<Absyn.Algorithm> alglst;
    Env.Env env1,env2;
  case(env,{}) then env;
  case(env, (alg as SCode.ALGORITHM(alglst,_)) :: algs)
    equation
      (env1) = evaluateAlgorithms(env,alglst);
      (env2) = evaluateAlgorithmsList(env1,algs);
    then
      env2;
end matchcontinue;  
end evaluateAlgorithmsList;

protected function evaluateAlgorithms "Function: evaluateAlgorithms 
helper function for evaluateAlgorithmsList
"
  input Env.Env env;
  input list<Absyn.Algorithm> inAlgs;
  output Env.Env outEnv;
algorithm
  outEnv := matchcontinue(env,inAlgs)
  local
    list<Absyn.Algorithm> algs;
    Absyn.Algorithm alg;
    Env.Env env1,env2;
    case(env,{}) then env;
    case(env, alg :: algs)
      equation
        (env1) = evaluateAlgorithm(env, alg);
        (env2) = evaluateAlgorithms(env1,algs);
        then
          env2;
    case(env,_::algs)
      equation
        Debug.fprint("failtrace", "- Cevalfunc.evaluateAlgorithms failed\n");
        then 
          fail();          
  end matchcontinue;  
end evaluateAlgorithms;

protected function evaluateAlgorithm "Function: evaluateAlgorithm 
This is the actuall evaluation function.
It matches the incoming algorithm types to a corresponding value/function. 
"
input Env.Env env;
input Absyn.Algorithm alg;
output Env.Env outEnv;
algorithm 
  outEnv := 
  matchcontinue(env,alg) 
      local 
        Absyn.Exp ae1,ae2,ae3,cond,msg;
        list<Absyn.Exp> crefexps;
        Exp.Exp econd,resExp,e1;
        Absyn.ComponentRef acr;
        Types.Type t,ty;
        Env.Env env1,env2,env3;
        Values.Value value,start,step,stop;
        list<Values.Value> values;
        list<Types.Type> types;
        Types.Properties prop;
        list<Absyn.AlgorithmItem> algitemlst;
        String varName;

        // assign, tuple assign
    case(env, Absyn.ALG_ASSIGN(ae1 as Absyn.CREF(_), ae2))
      equation
       (_,e1,Types.PROP(t,_),_) = Static.elabExp(Env.emptyCache,env,ae2,true,NONE,false); 
        (_,value,_) = Ceval.ceval(Env.emptyCache,env, e1, true, NONE, NONE, Ceval.MSG());
        env1 = setValue(value, env, ae1);
      then
        env1;
    case(env, Absyn.ALG_ASSIGN(assignComponent = Absyn.TUPLE(expressions = crefexps),value = ae1))
      equation
        (_,resExp,prop,_) = Static.elabExp(Env.emptyCache,env, ae1, true, NONE,true);
        ((Types.T_TUPLE(types),_)) = Types.getPropType(prop);
        (_,Values.TUPLE(values),_) = Ceval.ceval(Env.emptyCache,env, resExp, true, NONE, NONE, Ceval.MSG());
        env1 = setValues(crefexps,types,values,env);
        then
          env1;
          //while case
    case(env, Absyn.ALG_WHILE(whileStmt = ae1,whileBody = algitemlst))
      equation 
        value = evaluateSingleExpression(ae1,env,NONE);
        env1 = evaluateConditionalStatement(value, ae1, algitemlst,env);
      then 
        env1;    
        //Different for-cases
    case(env, Absyn.ALG_FOR({(varName, SOME(Absyn.RANGE(start=ae1,step=NONE, stop=ae2)))},forBody = algitemlst))
      equation 
        start = evaluateSingleExpression(ae1,env,NONE);
        ty = Types.typeOfValue(start);
        env1 = addForLoopScope(env,varName,ty);
        stop = evaluateSingleExpression(ae2,env1,NONE);
        step = Values.INTEGER(1);
        env2 = evaluateForLoopRange(env1, varName, algitemlst, start, step, stop);
      then
        env2;
    case(env, Absyn.ALG_FOR({(varName, SOME(Absyn.RANGE(start=ae1, step=SOME(ae2), stop=ae3)))},forBody = algitemlst))
      equation 
        start = evaluateSingleExpression(ae1,env,NONE);
        ty = Types.typeOfValue(start);
        env1 = addForLoopScope(env,varName,ty);
        stop = evaluateSingleExpression(ae3,env1,NONE);
        step = evaluateSingleExpression(ae2,env1,NONE);
        env2 = evaluateForLoopRange(env1, varName, algitemlst, start, step, stop);
      then
        env2;
    case(env, Absyn.ALG_FOR({(varName, SOME(ae1))},forBody = algitemlst))
      equation 
        (Values.ARRAY(values)) = evaluateSingleExpression(ae1, env,NONE);
        start = listNth(values,0);
        ty = Types.typeOfValue(start);
        env1 = addForLoopScope(env,varName,ty);
        env2 = evaluateForLoopArray(env1, varName, values, algitemlst);
      then
        env2;
    case(env,Absyn.ALG_FOR(iterators = {(_,SOME(ae1))})) 
      local
        String estr;
      equation 
        (_,e1,_,_) = Static.elabExp(Env.emptyCache,env, ae1, true, NONE,true);
        estr = Exp.printExpStr(e1);
        Error.addMessage(Error.NOT_ARRAY_TYPE_IN_FOR_STATEMENT, {estr});
      then 
        fail();
        //if-case
    case(env, Absyn.ALG_IF(ifExp = ae1,trueBranch = algitemlst,elseIfAlgorithmBranch = elseifexpitemlist,
        elseBranch = elseitemlist))
      local 
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> elseifexpitemlist,branches1,branches2;
      tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> trueBranch;
      list<Absyn.AlgorithmItem> algitemlist,elseitemlist;
      equation 
        trueBranch = (ae1,algitemlst);
        branches1 = (trueBranch :: elseifexpitemlist);
        branches2 = listAppend(branches1, {(Absyn.BOOL(true),elseitemlist)});
        env1 = evaluateIfStatementLst(branches2, env);
      then
        env1;
        // Asserts
    case(env, Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),
      functionArgs = Absyn.FUNCTIONARGS(args = {cond,msg})))
      equation 
        (_,econd,_,_) = Static.elabExp(Env.emptyCache,env, cond, true, NONE,true);
        (_,Values.BOOL(true),_) = Ceval.ceval(Env.emptyCache,env, econd, true, NONE, NONE, Ceval.MSG());
      then 
        env;
    case(env, Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),
      functionArgs = Absyn.FUNCTIONARGS(args = {cond,msg})))
      equation 
        (_,e1,_,_) = Static.elabExp(Env.emptyCache,env, msg, true, NONE,true);
        (_,Values.STRING(varName),_) = Ceval.ceval(Env.emptyCache,env, e1, true, NONE, NONE, Ceval.MSG());
        Error.addMessage(Error.ASSERT_FAILED, {varName});
      then
        fail();
  end matchcontinue;
end evaluateAlgorithm;

protected function evaluateIfStatementLst "
  Evaluates all parts of a if statement (i.e. a list of exp  statements)
"
input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inIfs;
input Env.Env env;
output Env.Env oenv;
algorithm oenv := matchcontinue(inIfs,env)
  local
      Values.Value value;
      Absyn.Exp ae1;
      list<Absyn.AlgorithmItem> algitemlst;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> algrest;
      Env.Env env1;
  case({},env) then env;
  case(((ae1,algitemlst)::algrest),env)
    equation
      value = evaluateSingleExpression(ae1,env,NONE);
      env1 = evaluatePartOfIfStatement(value, ae1, algitemlst, algrest, env);
      then 
        env1;
  end matchcontinue;
end evaluateIfStatementLst;

protected function evaluatePartOfIfStatement "function: evaluatePartOfIfStatement   
  Evaluates one part of a if statement, i.e. one \"case\". If the condition is true, the algorithm items
  associated with this condition are evaluated. The first argument returned is set to true if the 
  condition was evaluated to true. Fails if the value is not a boolean.
  Note that we are sending the expression as an value, so that it does not need to be evaluated twice. 
"
  input Values.Value inValue;
  input Absyn.Exp inExp;
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTplAbsynExpAbsynAlgorithmItemLstLst;
  input Env.Env env;
  output Env.Env oenv;
algorithm 
  oenv :=
  matchcontinue (inValue,inExp,inAbsynAlgorithmItemLst,inTplAbsynExpAbsynAlgorithmItemLstLst,env)
    local
      Env.Env env1;
      Boolean exp_val;
      list<Absyn.AlgorithmItem> algitemlst;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> algrest;
      String estr,tstr;
      tuple<Types.TType, Option<Absyn.Path>> vtype;
      Values.Value value;
      Absyn.Exp exp;
    case (Values.BOOL(boolean = true),_,algitemlst,_,env)
      equation 
        env1 = evaluateConditionalStatement2(algitemlst, env);
      then
        env1;
    case (Values.BOOL(boolean = false),_,algitemlst,algrest,env)
      equation 
        env1 = evaluateIfStatementLst(algrest, env);
      then
        env1;
    case (value,exp,algitemlst,algrest,env) /* Report type error */ 
      local Exp.Exp e1;
      equation 
        (_,e1,_,_) = Static.elabExp(Env.emptyCache,env,inExp,true,NONE,false); 
        estr = Exp.printExpStr(e1);
        vtype = Types.typeOfValue(value);
        tstr = Types.unparseType(vtype);
        Error.addMessage(Error.IF_CONDITION_TYPE_ERROR, {estr,tstr});
      then
        fail();
  end matchcontinue;
end evaluatePartOfIfStatement;

protected function evaluateSingleExpression "Function: evaluateSingleExpression
This function evaluates a single expression(mostly used in condition evaluation, for/while/if).
It also has an optional Types.Type input if we want a specific type we will try to cast the input 
to that type.
"
  input Absyn.Exp inExp "The Absyn Expression to evaluate";
  input Env.Env env "Current enviroment";
  input Option<Types.Type> expectedType "SOME(Types.Type) (convert into that type)";
  output Values.Value oval;
algorithm oval := matchcontinue(inExp,env,expectedType)
  local Exp.Exp e1,e2;
    Values.Value value;
  case(inExp,env,NONE)
    equation
      (_,e1,_,_) = Static.elabExp(Env.emptyCache,env,inExp,true,NONE,false); 
      (_,value,_) = Ceval.ceval(Env.emptyCache,env, e1, true, NONE, NONE, Ceval.MSG());
    then 
      value;
  case(inExp,env,SOME(ty))
    local Types.Type ty,ty2;
    equation      
      (_,e1,Types.PROP(ty2,_),_) = Static.elabExp(Env.emptyCache,env,inExp,true,NONE,false); 
      (e2,_) = Types.matchType(e1,ty2,ty);
      (_,value,_) = Ceval.ceval(Env.emptyCache,env, e2, true, NONE, NONE, Ceval.MSG());
    then 
      value;            
  case(_,_,_)
    equation
      Debug.fprint("failtrace", "- Cevalfunc.evaluateSingleExpression failed\n");
    then
      fail();
end matchcontinue;
end evaluateSingleExpression;

protected function evaluateForLoopArray "Function: evaluateForLoopArray
Evaluates a forloop while the for-values are in an array.
"
input Env.Env env; 
input String varName;
input list<Values.Value> forValues;
input list<Absyn.AlgorithmItem> statements;
output Env.Env oenv;
algorithm oenv:= matchcontinue(env,varName,forValues,statements)
  local
    list<Absyn.AlgorithmItem> statements;
    Values.Value value;
    list<Values.Value> values;
    Env.Env env1,env2,env3;
  case(env,_,{},_) then env;
  case(env,varName, value::values, statements)
    equation
      env1 = setValue(value,env,Absyn.CREF(Absyn.CREF_IDENT(varName,{})));
      env2 = evaluateConditionalStatement2(statements,env1);
      env3 = evaluateForLoopArray(env2,varName,values,statements);
      then
        env3;
end matchcontinue;
end evaluateForLoopArray;

protected function evaluateForLoopRange "Function: evaluateForLoopArray
Evaluates a forloop while the for-values are a range ex. 1:1:10.
"
  input Env.Env env; 
  input String varName;
  input list<Absyn.AlgorithmItem> statements;
  input Values.Value start;
  input Values.Value step;
  input Values.Value stop;
  output Env.Env oenv;
algorithm oenv:= matchcontinue(env,varName,statements,start,step,stop)
  local
    
    list<Absyn.AlgorithmItem> statements;
    Values.Value newVal;
    list<Values.Value> values;
    Env.Env env1,env2,env3;   
  case(env,varName,statements,start,step,stop) 
    equation
      true = Values.safeLessEq(start,stop);
      env1 = setValue(start,env,Absyn.CREF(Absyn.CREF_IDENT(varName,{})));
      env2 = evaluateConditionalStatement2(statements,env1);
      newVal = Values.safeIntRealOp(start,step,Values.ADDOP);
      env3 = evaluateForLoopRange(env2,varName,statements,newVal,step,stop);
    then
      env3;
  case(env,_,_,start,step,stop) 
    equation
      false = Values.safeLessEq(start,stop);
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
  output Env.Env oenv;
algorithm oenv := matchcontinue(cond,updateExp,algitemlst,env)
  local
    Absyn.AlgorithmItem algi;
    list<Absyn.AlgorithmItem> algis;
    Env.Env env1,env2;
    Values.Value value, value2;
    Exp.Exp e1;
  case(Values.BOOL(false),_,_ ,env) then env;
  case(Values.BOOL(true), updateExp,algis,env)
    equation
      env1 = evaluateConditionalStatement2(algis,env);
      value2 = evaluateSingleExpression(updateExp,env1,NONE);
      env2 = evaluateConditionalStatement(value2,updateExp,algis,env1);
    then 
      env2;
end matchcontinue;
end evaluateConditionalStatement;

protected function evaluateConditionalStatement2 "
A intermediate-function for evaluation algorithm statements.
"
input list<Absyn.AlgorithmItem> inalgs;
input Env.Env env;
output Env.Env oenv;
algorithm oenv := matchcontinue(inalgs,env)
  local 
    Absyn.Algorithm alg;
    Env.Env env1,env2; 
    list<Absyn.AlgorithmItem> rest;
  case({},env) then env;
  case(Absyn.ALGORITHMITEM(alg,_)::rest,env)
    equation 
      env1 = evaluateAlgorithm(env,alg);
      env2 = evaluateConditionalStatement2(rest,env1);
      then 
        env2;
  case(Absyn.ALGORITHMITEMANN(_)::rest,env)
    equation
      env1 = evaluateConditionalStatement2(rest,env);
    then 
      env1;
end matchcontinue;
end evaluateConditionalStatement2;

protected function setValues "Function: setValues
This function set multiple(tuple) values.
"
  input list<Absyn.Exp> tupleCrefs;
  input list<Types.Type> types;
  input list<Values.Value> varValues;
  input Env.Env env;
  output Env.Env oEnv;
algorithm oEnv := matchcontinue(tupleCrefs, types, varValues, env)
local
  Absyn.Exp cref;
  Types.Type ty;
  Values.Value value;
  list<Absyn.Exp> crefs;
  list<Types.Type> tys;
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
This funtion updates a generic-variable in the enviroment.
"
  input Values.Value inVal "new value for var";
  input Env.Env env "The enviroment the variable is in";
  input Absyn.Exp toAssign "The variable to assign";
  output Env.Env outVal;  
algorithm outVal := matchcontinue(inVal,env,toAssign)
    local 
      Types.Type t;
      Env.Env env1;
      String str; 
      Values.Value value,value2;
  case(value as Values.RECORD(_,vals,names),env,Absyn.CREF(Absyn.CREF_IDENT(str,subs)))
    local 
      list<Absyn.Subscript> subs;
      list<Types.Var> typeslst,nlist;
      Env.Frame fr;
      Env.Env complexEnv;
      list<Values.Value> vals;
      list<String> names;
    equation
      (_,_,t as (Types.T_COMPLEX(_,typeslst,_,_),_),_,_,_) = Lookup.lookupVar(Env.emptyCache,env, Exp.CREF_IDENT(str,Exp.OTHER(),{}));
      nlist = setValuesInRecord(typeslst,names,vals);
      fr = Env.newFrame(false); 
      complexEnv = makeComplexEnv({fr},nlist);
      env1 = Env.updateFrameV(env,
          Types.VAR(str,Types.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
            false,t,Types.VALBOUND(value)), Env.VAR_TYPED(), complexEnv);
    then
      env1;
    case(value,env,Absyn.CREF(Absyn.CREF_IDENT(str,subs)))
      local 
        list<Absyn.Subscript> subs;
      equation
        (_,_,t,Types.VALBOUND(value2),_,_) = Lookup.lookupVar(Env.emptyCache,env, Exp.CREF_IDENT(str,Exp.OTHER(),{}));
        value = mergeValues(value2,value,subs,env,t); 
        env1 = updateVarinEnv(env,str,value,t);
      then
        env1;
    case(value,env,me as Absyn.CREF(Absyn.CREF_QUAL(str,subs,child)))
      local 
        list<Absyn.Subscript> subs;        
        Absyn.ComponentRef child;
        Absyn.Exp me;
        Exp.ComponentRef eme;
        String str2;
      equation 
        (_,_,t,Types.VALBOUND(value2),_,_) = Lookup.lookupVar(Env.emptyCache,env, Exp.CREF_IDENT(str,Exp.OTHER(),{}));
        env1 = setQualValue(env,value,Absyn.CREF_QUAL(str,subs,child));
      then
        env1;
    case(_,_,Absyn.CREF(dbgcr))
      local String dbgString; Absyn.ComponentRef dbgcr;
      equation     
        (Absyn.CREF_IDENT(dbgString,_)) = Absyn.crefGetFirst(dbgcr);
        dbgString = Util.stringAppendList({"- Cevalfunc.setValue failed for ", dbgString,"\n"});
        Debug.fprint("failtrace", dbgString);
      then fail();
  end matchcontinue;
end setValue;

protected function addForLoopScope "function: addForLoopScope
  Adds a scope on the environment used in for loops.
  The name of the scope is for_scope_name, defined as a value.
"
  input Env.Env env;
  input String i;
  input Types.Type typ;
  output Env.Env env_2;
  list<Env.Frame> env_1,env_2;
  Values.Value baseValue;
algorithm 
  baseValue := typeOfValue(typ);
  env_1 := Env.openScope(env, false, SOME(forScopeName));
  env_2 := Env.extendFrameV(env_1, 
          Types.VAR(i,Types.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
          false,typ,Types.VALBOUND(baseValue)), NONE, Env.VAR_UNTYPED(), {}) "comp env" ;
end addForLoopScope;

protected function setQualValue "Function: setQualValue
This function sets the value of a qual complex var. 
"
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
    list<Env.Frame> farg5;
    tuple<list<Exp.ComponentRef>,Exp.ComponentRef> farg6;
    Boolean farg7;
    
    String str;
    Absyn.ComponentRef child;
    Integer hash;
  case( ( (frame as Env.FRAME(farg1, farg2, farg3, farg4, farg5, farg6, farg7) ) :: frames), 
    inVal,inCr)    
    equation
      str = Absyn.crefFirstIdent(inCr);
      (_,_,_,_,_,_) = Lookup.lookupVar(Env.emptyCache, {frame}, Exp.CREF_IDENT(str,Exp.OTHER(),{}));
      farg22 = setQualValue2(farg2, inVal,inCr,0);
      then
        Env.FRAME(farg1,farg22,farg3,farg4,farg5,farg6,farg7) :: frames;    
  case( frame :: frames, inVal,inCr ) // didn't find in this frame. 
    equation 
      newFrames = setQualValue(frames,inVal,inCr);
      then
        frame::newFrames;
  case(_,_,_) 
    equation 
      Debug.fprint("failtrace", "- Cevalfunc.setQualValue failed\n");       
      then fail();
  end matchcontinue;  
end setQualValue;

protected function setQualValue2 "Function: setQualValue2
Helper function for setQualValue
"
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
    Types.Var fv;
    Option<tuple<SCode.Element, Types.Mod>> c ;
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
on the identifier \"varName\". If the variable is not there, extend the enviroment.
" 
  input Env.Env env "The variables enviroment";
  input String varName "The IDENT to update";
  input Values.Value newVal "The new value of the variable";
  input Types.Type ty "Type of variable";
  output Env.Env outEnv "The new updated enviroment";
algorithm
  outEnv := 
  matchcontinue(env,varName,newVal,ty)
    local Env.Env env1;
    case(env,varName,newVal,ty) 
      equation
        (_,_,_,_,_,_) = Lookup.lookupVar(Env.emptyCache, env,Exp.CREF_IDENT(varName,Exp.OTHER(),{}));
        env1 = Env.updateFrameV(env, 
          Types.VAR(varName,Types.ATTR(false,false,SCode.RW(),SCode.VAR(),Absyn.BIDIR(),Absyn.UNSPECIFIED()),
            false,ty,Types.VALBOUND(newVal)), Env.VAR_TYPED(), {}); 
      then
        env1;
    case(_,_,_,_) equation 
      Debug.fprint("failtrace", "- Cevalfunc.updateVarinEnv failed\n"); 
      then fail();
  end matchcontinue;
end updateVarinEnv;

protected function makeBinding "Function: makeBinding
This function will evaluate possible mods(input) and if a bindingvalue is found it will 
return a Types.VALBOUND otherwise a Types.UNBOUND
"
  input SCode.Mod inMod;
  input Env.Env env;
  input Types.Type baseType;
  output Types.Binding outBind;
  
algorithm 
  outBind := 
  matchcontinue(inMod,env,baseType)
    local
      tuple<Absyn.Exp,Boolean> absynExp;
      Absyn.Exp ae1;
      Exp.Exp e1;
      Values.Value value,value2,baseValue;
      Types.Type ty;
    case(SCode.MOD(absynExpOption = SOME(absynExp), eachPrefix = Absyn.NON_EACH) ,env,ty ) 
      equation        
        ae1 = Util.tuple21(absynExp);
        value = evaluateSingleExpression(ae1,env,SOME(ty));        
      then 
        Types.VALBOUND(value);
    case(SCode.MOD(absynExpOption = SOME(absynExp), eachPrefix = Absyn.EACH) ,env,ty ) 
      equation        
        ae1 = Util.tuple21(absynExp);
        value = evaluateSingleExpression(ae1,env,SOME(ty));
        value2 = instFunctionArray(ty,SOME(value));
      then 
        Types.VALBOUND(value2);
    case(SCode.MOD(absynExpOption = NONE),_,ty)
      equation 
        baseValue = instFunctionArray(ty,NONE);
      then 
        Types.VALBOUND(baseValue);
    case(SCode.NOMOD,_,ty)
      equation 
        baseValue = instFunctionArray(ty,NONE);
      then 
        Types.VALBOUND(baseValue);        
    case(SCode.MOD(absynExpOption = SOME(absynExp)),_,_)
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
input Types.Type inType;
input Option<Values.Value> optVal;
output Values.Value outArrOfZeroes;

algorithm 
  outArrOfZeroes :=
  matchcontinue(inType,optVal)
      local 
        Types.Type ty,ty2,bt;
        Types.ArrayDim ad;
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
input Types.Type inType;
input Option<Values.Value> optVal;
output Values.Value outArrOfZeroes;

algorithm 
  outArrOfZeroes :=
  matchcontinue(inDims,inType,optVal)
      local 
        Types.Type ty,ty2,bt;
        Types.ArrayDim ad;
        Values.Value value,val;
        list<Values.Value> values;
        Integer dim;
        list<Integer> dims;

    case(dim :: dims, ty ,optVal)
      equation
        true = (listLength(inDims)>0);
        value = instFunctionArray2(dims, ty,optVal);
        values = Util.listFill(value,dim);
        value = Values.ARRAY(values);
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
input Types.Type inType;
output Values.Value oval;
algorithm oval := matchcontinue(inType)
  case((Types.T_INTEGER(_),_)) then Values.INTEGER(0);
  case((Types.T_REAL(_),_)) then Values.REAL(0.0);
  case((Types.T_STRING(_),_)) then Values.STRING("");
  case((Types.T_BOOL(_),_)) then Values.BOOL(false);
  case((Types.T_ENUM,_)) then Values.ENUM(Exp.CREF_IDENT("",Exp.ENUM(),{})); 
  case((Types.T_COMPLEX(ClassInf.RECORD(str), typesVar,_,_),_))
    local 
      list<Types.Var> typesVar;
      String str;
    equation
      
      then
        Values.RECORD(Absyn.IDENT(str),{},{}) ;
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
    list<Exp.Ident> comp "comp names for each value" ;
  end RECORD;
  */
end matchcontinue;
end typeOfValue;

protected function getTypeFromName "function: getTypeFromName 
  Returns the type specified by the cref.
"
  input Absyn.Path inPath;
  input Env.Env env;
  output Types.Type outType;  
algorithm 
  outType:=
  matchcontinue (inPath,env)
    local
      Types.Type ty;
      list<Integer> dims;
      String typeName,className;
      Absyn.Path rest,p;
      SCode.Class typeClass;
      Env.Env env1,env2;
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
        (_,typeClass as SCode.CLASS(name=className),env1) = Lookup.lookupClass(Env.emptyCache, env, p, false);
        (_,_,env2,_,ty,_,_,_) = Inst.instClass(
          Env.emptyCache,env1,Types.NOMOD(),Prefix.NOPRE(),Connect.emptySet,typeClass,{}, true, Inst.INNER_CALL, ConnectionGraph.EMPTY);
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
  output Types.Type outType;  
algorithm 
  outType:=
  matchcontinue (inString)
    local
      String nonBuiltin;
      SCode.Class typeClass;
    case ("Integer") then ((Types.T_INTEGER({}),NONE));
    case ("Real") then ((Types.T_REAL({}),NONE));
    case ("String") then ((Types.T_STRING({}),NONE));
    case ("Boolean") then ((Types.T_BOOL({}),NONE));

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
        (_,_,_,Types.VALBOUND(value),_,_) = Lookup.lookupVar(Env.emptyCache,env, Exp.CREF_IDENT(varName,Exp.OTHER(),{}));
        lval = getOutputVarValues(eles1,env);
      then
       value::lval; 
    case(_::eles1,env)
      equation
        lval = getOutputVarValues(eles1,env);
        then
          lval;
  end matchcontinue;
end getOutputVarValues;

protected function convertOutputVarValues "Function: convertOutputVarValues
This function converts a list of values to a single value.
Eighter a Values.INTEGER etc. or a Values.ARRAY(list).
This to work with multiple outputs(tuple return) "
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

public function mergeValues "Function: mergeValues
This function will update a specific value location.
"
input Values.Value oldVal "This is the old value, to update inside";
input Values.Value newVal "This is the new value, which we will insert into returning Value";
input list<Absyn.Subscript> insubs;
input Env.Env env;
input Types.Type ty;
output Values.Value oval;
algorithm oval := matchcontinue(oldVal,newVal,insubs,env,ty)
  local 
    Absyn.Subscript sub;
    list<Absyn.Subscript> subs;
    Values.Value value,val1,val2,val3;
    list<Values.Value> values1,values2,values3,values4;
    Exp.Exp e1;
    Integer x;
    Absyn.Exp exp;
    case(_,newVal,{},_,ty) 
      equation 
        (ty,_) = Types.flattenArrayType(ty); 
        value = checkValueTypes(newVal,ty);
        then value;

  case((oldVal as Values.ARRAY(valueLst = values1)),newVal,((sub as Absyn.SUBSCRIPT(exp))::subs),env,ty)
    equation
      (_,e1,_,_) = Static.elabExp(Env.emptyCache,env,exp,true,NONE,false); 
      (_,value as Values.INTEGER(x),_) = Ceval.ceval(Env.emptyCache,env, e1, true, NONE, NONE, Ceval.MSG());
      val1 = listNth(values1 ,(x-1)); // to be replaced
      val2 = mergeValues(val1,newVal,subs,env,ty);
      values2 = Util.listReplaceAt(val2,(x-1),values1);
      val3 = Values.ARRAY(values2);
    then
      val3;
  case((oldVal as Values.ARRAY(valueLst = values1)),(newVal as Values.ARRAY(valueLst = values2)),((sub as Absyn.NOSUB)::subs),env,ty)
    equation
      values3 = mergeValues2(values1,values2,subs,env,ty);
      val3 = Values.ARRAY(values3);
    then
      val3;
  end matchcontinue;
end mergeValues;

protected function mergeValues2 ""
input list<Values.Value> oldVal;
input list<Values.Value> newVal;
input list<Absyn.Subscript> insubs;
input Env.Env env;
input Types.Type ty;
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
This function takes a Values.Value and a Types.Type 
Checks if the Value corresponds to the type.
If value is a Integer and Type is Real, it it converted to a real Value. 
" 
input Values.Value val;
input Types.Type ty;
output Values.Value outVal;
algorithm outVal := matchcontinue(val,ty) 
  local
    list<Values.Value> vals1,vals2;
    Values.Value val1,val2;
    Integer ix;
    Real rx;
  case(Values.ARRAY(vals1), ty as (Types.T_REAL(_),_)) 
    equation 
      vals2 = Util.listMap1(vals1,checkValueTypes,ty) ;
      val1 = Values.ARRAY(vals2); 
    then
      val1;
  case(Values.ARRAY(vals1), ty as (Types.T_INTEGER(_),_)) 
    equation 
      vals2 = Util.listMap1(vals1,checkValueTypes,ty);
      val1 = Values.ARRAY(vals2); 
    then
      val1;
  case(Values.INTEGER(ix), ty as (Types.T_REAL(_),_))
    equation 
    rx = intReal(ix);
      then
        Values.REAL(rx);
  case(Values.REAL(rx), ty as (Types.T_INTEGER(_),_))
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
  input Types.Type ty "The raw type";
  input Absyn.ArrayDim arrayDim "The dimensions to add";
  input Env.Env env "Variables enviroment"; 
  output Types.Type outType "resulting type";
algorithm outType := matchcontinue(ty,arrayDim,env)
  local 
    Absyn.Subscript sub1;
    list<Absyn.Subscript> subs1;
    Absyn.Exp exp;
    Integer x;
    Values.Value val;
  case(ty,{},_) then ty;
  case(ty, (sub1 as Absyn.SUBSCRIPT(exp))::subs1,env)
    equation 
      (val as Values.INTEGER(x)) = evaluateSingleExpression(exp,env,NONE);
      ty = Types.liftArrayRight(ty,SOME(x));
      ty = addDims(ty,subs1,env);
    then 
      ty;
end matchcontinue;
end addDims;

end Cevalfunc;
