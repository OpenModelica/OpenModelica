/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
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

// two functions "addLabelToExpList" and "addLabelToExpListForSubstitution", were commented in old version


encapsulated package ReduceDAE
public  import Absyn;
public import BackendDAE;
public import BackendVarTransform;
public import DAE;
public import Expression;
public import List;
public import SimCode;
public import SimCodeFunction;
public import SimCodeVar;

protected
import ComponentReference;
import Debug;
import Differentiate;
import ExpressionDump;
import ExpressionSimplify;
import Flags;
import Util;
public constant String LABELNAME="label";


public function buildLabels
"main function for labeling equations -- needed for ranking procedure"
  input list<SimCode.SimEqSystem> inEquationLst;  //equations to be labeled
  input SimCode.ModelInfo inModelInfo;            //model info for variables, variable info and labels
  input list <Integer> reduceList;                //for replace terms: numbers of labels that need to be replaced
  input Absyn.FunctionArgs inArgs;                //function arguments: mean values for linearization
  output list<SimCode.SimEqSystem> outEquationLst;
  output SimCode.ModelInfo outModelInfo;
algorithm
  (outEquationLst,outModelInfo):=
  matchcontinue (inEquationLst,inModelInfo,reduceList,inArgs)
    local
      Absyn.FunctionArgs args;
      SimCode.ModelInfo modelInfo;
      list<SimCode.SimEqSystem> eqns,eqns_1;
      Absyn.Path name;
      list<SimCode.SimEqSystem> linearSystems;
      list<SimCode.SimEqSystem> nonLinearSystems;
      String description,directory;
      SimCode.VarInfo varInfo,varInfo_1;
      SimCodeVar.SimVars vars,vars_1;
      list<SimCodeFunction.Function> functions;
      Boolean hasLargeLinearEquationSystems;
      Integer nClocks,nSubClocks;
      list<SimCodeVar.SimVar> states,derVar,alg,intAlg,boolAlg,inVar,outVar,algAlias,intAlias,boolAlias,param,
                           intParam,boolParam,stringAlg,stringParam,stringAlias,extObjVar,jacobianVar,const,intConst,boolConst,stringConst;

      Integer nZC,nTE,nR,nMEF,nStates,nAlg,nDiscReal,nIntAlg,nBoolAlg,nAlgAlias,nIntAlias,nBoolAlias,
              nParam,nIntParam,nBoolParam,nOut,nIn,nExtObj,nStringAlg,nStringParam,nStringAlias,nEq,nLSys,nNLSys,nMixSys,
        nStateSet,nJacobian,nOptCons,nOptFinalConst,nSensParam;

      list<String> labels,labels_1,labels_2;
      Integer i,p;
      list<Absyn.Exp> exp_list;
      BackendVarTransform.VariableReplacements repl;
    case (eqns,modelInfo as SimCode.MODELINFO(varInfo=varInfo as SimCode.VARINFO()),_,Absyn.FUNCTIONARGS(args = {Absyn.CREF(_), Absyn.ARRAY(arrayExp = exp_list)}))
      algorithm
        //create replacements for algebraic and state variables together with the time variable by their average values
        repl:=meanValueReplacements(modelInfo.vars,exp_list);
        //add labels to equations
        (eqns_1,vars_1,(i,p),labels_1):=addLabelToEquations(eqns,modelInfo.vars,(0,varInfo.numParams),reduceList,repl);
        //append original (empty list) and created labels
        labels_2:=listAppend(modelInfo.labels,labels_1);
        //update number of parameters in the varInfo nParam=p
        if varInfo.numParams <> p then
          varInfo.numParams := p;
          modelInfo.varInfo := varInfo;
        end if;
        modelInfo.labels := labels_2;
        if not referenceEq(modelInfo.vars, vars_1) then
          modelInfo.vars := vars_1;
        end if;
      then
        (eqns_1,modelInfo);

    //this case is only necessary for calling generateLabeledDAE from Eclipse, because the first case fails, because there are no inArgs
    case (eqns,modelInfo as SimCode.MODELINFO(varInfo=varInfo as SimCode.VARINFO()),_,args)
      algorithm
        repl:=BackendVarTransform.emptyReplacements();
        (eqns_1,vars_1,(i,p),labels_1):=addLabelToEquations(eqns,modelInfo.vars,(0,varInfo.numParams),reduceList,repl);
        labels_2:=listAppend(modelInfo.labels,labels_1);
        if varInfo.numParams <> p then
          varInfo.numParams := p;
          modelInfo.varInfo := varInfo;
        end if;
        modelInfo.labels := labels_2;
        if not referenceEq(modelInfo.vars, vars_1) then
          modelInfo.vars := vars_1;
        end if;
      then
        (eqns_1,modelInfo);
  end matchcontinue;
end buildLabels;


public function reduceTerms
"function that replaces terms with labels given by inArgs"
  input list<SimCode.SimEqSystem> inEquationLst;
  input SimCode.ModelInfo inModelInfo;
  input Absyn.FunctionArgs inArgs;
  output list<SimCode.SimEqSystem> outEquationLst;
  output SimCode.ModelInfo outModelInfo;
algorithm
  (outEquationLst,outModelInfo):=
  matchcontinue (inEquationLst,inModelInfo,inArgs)
    local
      Absyn.FunctionArgs arg;
     // list<BackendDAE.Equation> seqnsl,ieqnsl,seqnsl_1,ieqnsl_1;
     // list<list<BackendDAE.Equation>> eqnsl,eqnsl_1;
      list<SimCode.SimEqSystem> eqns,eqns_1;
      //BackendDAE.MultiDimEquation[:] ae_1,ae;
     // DAE.Algorithm[:] al;
      //list<BackendDAE.WhenClause> wc;
      //list<BackendDAE.ZeroCrossing> zc;
      //BackendDAE.Variables knvars_1,knvars,extVars;
      //BackendDAE.EquationArray seqns_1,ieqns_1,seqns,ieqns;
     // BackendDAE.BackendDAE reduced_dae,dae;
     // BackendDAE.ExternalObjectClasses extObjCls;
     // list<String> labels;
      Integer n;
      list <Integer> reduceList,keep_lst;
      list<Absyn.Exp> exp_list,exp_list2,inExpArgList;
      list<Absyn.NamedArg> inNamedArgList;
      list<String> outStringList;
      list<Absyn.Exp> outExpList;
      String st;
      String reduceListStr="";
      //BackendVarTransform.VariableReplacements repl,repl_2,repl_3;
      //list<BackendDAE.MultiDimEquation> arreqnsl,arreqnsl_1;
     // BackendDAE.BinTree movedvars_1,movedvars_2;
      //BackendDAE.EqSystems eqs,eqs_1;
      //BackendDAE.AliasVariables aVars;
     // BackendDAE.BackendDAEType daeType;
      Absyn.ComponentRef cr;
      SimCode.ModelInfo modelInfo,modelInfo_1;

     case (eqns,modelInfo,Absyn.FUNCTIONARGS(args=inExpArgList,argNames=inNamedArgList))
      equation
        //make an integer list of labels to be reduced

         (outStringList,outExpList) = Absyn.getNamedFuncArgNamesAndValues(inNamedArgList);

        reduceListStr=System.stringReplace(ExpressionDump.printExpStr(Expression.fromAbsynExp(listGet(outExpList,1))), "\"", "");
        reduceList=StringDelimit2Int(reduceListStr,",");
        //reduce terms by calling buildLabels (buildLabels functions differently depending whether GENERATE_LABELED_SIMCODE or REDUCE_TERMS is enabled)
       (eqns,modelInfo_1)= buildLabels(eqns,modelInfo,reduceList,Absyn.FUNCTIONARGS(args=inExpArgList,argNames=inNamedArgList));

      then
        (eqns,modelInfo_1);

  end matchcontinue;
end reduceTerms;


protected function meanValueReplacements
"Creates replacements for algebraic and state variables by the values given in exp_list, last value is for the time variable."
  input SimCodeVar.SimVars inVarLst;
  input list<Absyn.Exp> exp_list;
  output BackendVarTransform.VariableReplacements outVarRepl;
algorithm
  outVarRepl:=matchcontinue(inVarLst,exp_list)
    local
      list<SimCodeVar.SimVar> alg,intAlg,boolAlg,states,listVars,listVars1,listVars2;
      BackendVarTransform.VariableReplacements repl;
    case(SimCodeVar.SIMVARS(algVars=alg,intAlgVars=intAlg,boolAlgVars=boolAlg,stateVars=states),_)
      equation
        //empty replacements
        repl=BackendVarTransform.emptyReplacements();
        //create a list of algVars, intAlgVars, boolAlgvars and stateVars
        listVars1 = listAppend(alg,intAlg);
        listVars2 = listAppend(listVars1,boolAlg);
        listVars = listAppend(listVars2,states);
        repl=meanValueReplacements2(repl,listVars,exp_list);
      then repl;
  end matchcontinue;
end meanValueReplacements;


protected function meanValueReplacements2
"helper function for meanValueReplacements"
  input BackendVarTransform.VariableReplacements inVarRepl;
  input list<SimCodeVar.SimVar> inVarList;
  input list<Absyn.Exp> inValuesList;
  output  BackendVarTransform.VariableReplacements outVarRepl;
algorithm
  outVarRepl:=matchcontinue(inVarRepl,inVarList,inValuesList)
    local
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef name;
      DAE.Type type_;
      list<SimCodeVar.SimVar> restVar;
      String value;
      Integer value2;
      Absyn.Operator op;
      list<Absyn.Exp> restVal;
      SimCodeVar.SimVar var;
      Absyn.Exp meanValue,exp;
    case(repl,{},{}) then repl;
    //adds replacement for the time variable
    case(repl,{},Absyn.REAL(value)::{})
      equation

        repl=BackendVarTransform.addReplacement(repl,DAE.crefTime,DAE.RCONST(stringReal(value)),NONE());

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("Add replacement for time \n" );
    end if;

        //Debug.fcall(Flags.CPP,print,"Add replacement for time \n" );

      then repl;
    //replacements for real values
    case(repl,SimCodeVar.SIMVAR(name = name,type_ = DAE.T_REAL(_))::restVar,Absyn.REAL(value)::restVal)
      equation
        repl=BackendVarTransform.addReplacement(repl,name,DAE.RCONST(stringReal(value)),NONE());
        repl=meanValueReplacements2(repl,restVar,restVal);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("Add replacement for " + ComponentReference.printComponentRefStr(name) + " by " + value + "\n" );
    end if;

      then repl;
    //replacements for integer values
    case(repl,SimCodeVar.SIMVAR(name = name,type_ = DAE.T_REAL(_))::restVar,Absyn.INTEGER(value = value2)::restVal)
      equation
        value=intString(value2);
        repl=BackendVarTransform.addReplacement(repl,name,DAE.RCONST(stringReal(value)),NONE());
        repl=meanValueReplacements2(repl,restVar,restVal);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("Add replacement for " + ComponentReference.printComponentRefStr(name) + " by " + value + "\n" );
    end if;
      then repl;
    //replacements for negative reals
    case(repl,SimCodeVar.SIMVAR(name = name,type_ = DAE.T_REAL(_))::restVar,Absyn.UNARY(op = Absyn.UMINUS(),exp = Absyn.REAL(value))::restVal)
      equation
        repl=BackendVarTransform.addReplacement(repl,name,DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT),DAE.RCONST(stringReal(value))),NONE());
        repl=meanValueReplacements2(repl,restVar,restVal);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("Add replacement for " + ComponentReference.printComponentRefStr(name) + " by -" + value + "\n" );
    end if;

        //Debug.fcall(Flags.CPP,print,"Add replacement for " + ComponentReference.printComponentRefStr(name) + " by -" + realString(value) + "\n" );

      then repl;
    //replacements for negative integers
    case(repl,SimCodeVar.SIMVAR(name = name,type_ = DAE.T_REAL(_))::restVar,Absyn.UNARY(op = Absyn.UMINUS(),exp = Absyn.INTEGER(value2))::restVal)
      equation
        value=intString(value2);
        repl=BackendVarTransform.addReplacement(repl,name,DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT),DAE.RCONST(stringReal(value))),NONE());
        repl=meanValueReplacements2(repl,restVar,restVal);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("Add replacement for " + ComponentReference.printComponentRefStr(name) + " by -" + value + "\n" );
    end if;
      then repl;
    case(repl,var::restVar,meanValue::restVal)
      equation
        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("Add no replacement \n" );
    end if;

      then repl;
    case(repl,var::restVar,meanValue::restVal)
      equation
        repl=meanValueReplacements2(repl,restVar,restVal);
      then repl;
  end matchcontinue;
end meanValueReplacements2;


protected function addLabelToEquations
"function that calls addLabelToExp for different kinds of SimCode.SimEqSystems"
  input  list<SimCode.SimEqSystem> inEquationLst1;
  input  SimCodeVar.SimVars inVarLst;
  input  tuple<Integer,Integer> inIndex;
  input  list <Integer> reduceList;
  input BackendVarTransform.VariableReplacements inVarRepl;
  output list<SimCode.SimEqSystem> outEquationLst;
  output SimCodeVar.SimVars outVarLst;
  output tuple<Integer,Integer> outIndex;
  output list<String> outStringList;
  algorithm
  (outEquationLst,outVarLst,outIndex,outStringList) := matchcontinue (inEquationLst1,inVarLst,inIndex,reduceList,inVarRepl)
    local
      DAE.Exp e,e1_1,e2_1,e1,e2,cond;
      list<SimCode.SimEqSystem> es_1,es,nl,nl_1,disc;
      SimCode.SimEqSystem cont,cont_1,eq,elsePart;
      DAE.ComponentRef left;
      DAE.Exp right;
      list<DAE.Exp> s,t,inputs,outputs,expl,b;
      DAE.ComponentRef cr_1,cr;
      DAE.ElementSource source "origin of the equation";
    list<DAE.ElementSource> sourcelist;
      SimCodeVar.SimVars vars,vars_1,vars_2,vars_3;
      list<String> labels,labels2,labels3,labels4,labels5;
      tuple <Integer,Integer> idx,idx2,idx3,idx4;
      Integer i,indexSys,idxLS,idxNLS,nUnknownsLS,nUnknownsNLS;
      list<DAE.ComponentRef> conditions;
    Boolean partOfLinear,tornSystem,initialCall;
     list<BackendDAE.WhenOperator> whenStmtLst;
      list<tuple<Integer, Integer, SimCode.SimEqSystem>> A,A2;
      list<DAE.ComponentRef> crefs,crefs_1;
      list<SimCodeVar.SimVar> varsLin,discVars;
      list<DAE.Statement> statements,statements2;
   list<SimCode.SimEqSystem> residual;
    Option<SimCode.JacobianMatrix> jacobianMatrix;
      BackendDAE.EquationAttributes eqAttr;

    // nothing
    case ({},vars,idx,_,_) then ({},vars,idx,{});
    // residuals
    case (((eq as SimCode.SES_RESIDUAL(i,e,source, eqAttr)) :: es),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("---Replace residuals  \n" );
    end if;

        //label a residual equation
        (e2,vars_1,idx2,labels) = addLabelToExp(e,vars,idx,true,reduceList,inVarRepl);
        //simplify the labeled equation
        (e2,_)=ExpressionSimplify.simplify(e2);
        //label rest
        (es_1 ,vars_2,idx3,labels2)= addLabelToEquations(es,vars_1,idx2,reduceList,inVarRepl);
        labels3=listAppend(labels,labels2);
      then
        (SimCode.SES_RESIDUAL(i,e2,source, eqAttr) :: es_1,vars_2,idx3,labels3);
    // simple assignments
    case (((eq as SimCode.SES_SIMPLE_ASSIGN(i,cr,e,source, eqAttr)) :: es),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("---Replace simple assignments  \n" );
    end if;
        //label simple assigment
        (e2,vars_1,idx2,labels) = addLabelToExp(e,vars,idx,true,reduceList,inVarRepl);
        //simplify the labeled equation
        (e2,_)=ExpressionSimplify.simplify(e2);
        //label rest
        (es_1 ,vars_2,idx3,labels2)= addLabelToEquations(es,vars_1,idx2,reduceList,inVarRepl);
        labels3=listAppend(labels,labels2);
      then
        (SimCode.SES_SIMPLE_ASSIGN(i,cr,e2,source, eqAttr) :: es_1,vars_2,idx3,labels3);
    // algorithms
    case (((eq as SimCode.SES_ALGORITHM(i,statements, eqAttr)) :: es),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("---Replace algorithms  \n" );
    end if;

        //Debug.fcall(Flags.CPP,print,"---Replace algorithms  \n" );

        //call helper function for labeling algorithms
        (statements2,vars_1,idx2,labels)=addLabelToAlgorithms(statements,vars,idx,reduceList,inVarRepl);
        //label rest
        (es_1 ,vars_2,idx3,labels2)= addLabelToEquations(es,vars_1,idx2,reduceList,inVarRepl);
        labels3=listAppend(labels,labels2);
      then
        (SimCode.SES_ALGORITHM(i,statements2, eqAttr) :: es_1,vars_2,idx3,labels3);
    // linear systems
    case (((eq as SimCode.SES_LINEAR (SimCode.LINEARSYSTEM(i,partOfLinear,tornSystem,varsLin,b,A,residual,jacobianMatrix,sourcelist,idxLS,nUnknownsLS),NONE(), eqAttr)) :: es),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("---Replace linear equation systems  \n" );
    end if;
        //call helper function for labeling linear equation systems
        (A2,vars_1,idx2,labels)=addLabelToLinearEquationSystems(A,vars,idx,reduceList,inVarRepl);
        //label rest
        (es_1 ,vars_2,idx3,labels2)= addLabelToEquations(es,vars_1,idx2,reduceList,inVarRepl);
        labels3=listAppend(labels,labels2);

      then
        (SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(i,partOfLinear,tornSystem,varsLin,b,A2,residual,jacobianMatrix,sourcelist,idxLS,nUnknownsLS),NONE(), eqAttr) :: es_1,vars_2,idx3,labels3);
    // non-linear systems
    case (((eq as SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(index=i,eqs=nl,crefs=crefs,indexNonLinearSystem=idxNLS,nUnknowns=nUnknownsNLS,jacobianMatrix=jacobianMatrix),NONE(), eqAttr)) :: es),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("---Replace non-linear equation systems  \n" );
    end if;
        //call addLabelToEquations for equations in a nonlinear equation system
        (nl_1,vars_1,idx2,labels)=addLabelToEquations(nl,vars,idx,reduceList,inVarRepl);
        //label rest
        (es_1 ,vars_2,idx3,labels2)= addLabelToEquations(es,vars_1,idx2,reduceList,inVarRepl);
        labels3=listAppend(labels,labels2);
      then
        (SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(index=i,eqs=nl_1,crefs=crefs,indexNonLinearSystem=idxNLS,nUnknowns=nUnknownsNLS,jacobianMatrix=jacobianMatrix,homotopySupport=false,mixedSystem=false,tornSystem=false),NONE(), eqAttr) :: es_1,vars_2,idx3,labels3);
    // mixed systems
    case (((eq as SimCode.SES_MIXED(i,cont,discVars,disc,indexSys, eqAttr)) :: es),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("---Replace mixed equation systems  \n" );
    end if;
        //call addLabelToEquations for equations in a mixed system
        ({cont_1},vars_1,idx2,labels)=addLabelToEquations({cont},vars,idx,reduceList,inVarRepl);
        //label rest
        (es_1 ,vars_2,idx3,labels2)= addLabelToEquations(es,vars_1,idx2,reduceList,inVarRepl);
        labels3=listAppend(labels,labels2);
      then
        (SimCode.SES_MIXED(i,cont_1,discVars,disc,indexSys, eqAttr) :: es_1,vars_2,idx3,labels3);
    // when without else
  case (((eq as SimCode.SES_WHEN(i,conditions,initialCall,whenStmtLst,NONE(),source, eqAttr)) :: es),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("---Replace when equations without else statement  \n" );
    end if;
        //label rest
        (es_1 ,vars_1,idx2,labels)= addLabelToEquations(es,vars,idx,reduceList,inVarRepl);
      then
        //(SimCode.SES_WHEN(i,conditions,initialCall,whenStmtLst,NONE(),source, eqAttr) :: es_1,vars,idx2,labels);
        (SimCode.SES_WHEN(i,conditions,initialCall,whenStmtLst,NONE(),source, eqAttr) :: es_1,vars_1,idx2,labels);
    // when with else
    case (((eq as SimCode.SES_WHEN(i,conditions,initialCall,whenStmtLst,SOME(elsePart),source, eqAttr)) :: es),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("---Replace when equations with else statement  \n" );
    end if;
        //label when equations
        //call addLabelToEquations for labeling else part
        ({elsePart} ,vars_1,idx2,labels)= addLabelToEquations({elsePart},vars,idx,reduceList,inVarRepl);
        //label rest
        (es_1 ,vars_2,idx3,labels2)= addLabelToEquations(es,vars_1,idx2,reduceList,inVarRepl);
        labels3=listAppend(labels,labels2);
      then
        (SimCode.SES_WHEN(i,conditions,initialCall,whenStmtLst,SOME(elsePart),source, eqAttr) :: es_1,vars_2,idx3,labels3);
    // add other types of equations
    // unknown equations
    case (eq::es,vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("---Replace unknown equations  \n" );
    end if;

        //Debug.fcall(Flags.CPP,print,"---Replace unknown equations  \n" );

        (es_1,vars_1,idx2,labels) = addLabelToEquations(es,vars,idx,reduceList,inVarRepl);
      then
        (eq::es_1,vars_1,idx2,labels);
  end matchcontinue;
end addLabelToEquations;

protected function addLabelToAlgorithms
"helper function for labeling algorithms"
  input  list<DAE.Statement> inStatements;
  input  SimCodeVar.SimVars inVarLst;
  input  tuple<Integer,Integer> inIndex;
  input  list <Integer> reduceList;
  input  BackendVarTransform.VariableReplacements inVarRepl;
  output list<DAE.Statement> outStatements;
  output SimCodeVar.SimVars outVarLst;
  output tuple<Integer,Integer> outIndex;
  output list<String> outStringList;
  algorithm
  (outStatements,outVarLst,outIndex,outStringList) := matchcontinue (inStatements,inVarLst,inIndex,reduceList,inVarRepl)
    local
      SimCodeVar.SimVars vars,vars_1,vars_2,vars_3;
      tuple <Integer,Integer> idx,idx2,idx3,idx4;
      SimCode.SimEqSystem el,el2;
      list<DAE.Statement> rest,rest2,stmtLst,stmtLst2;
      list<String> labels,labels2,labels3,labels4,labels5;
      DAE.Type ty;
      DAE.Exp e,e1,e2,e3;
      DAE.ElementSource source;
      DAE.Statement stmt, elseWhen, elseWhen2;
      DAE.Else else_;
      Boolean iterIsArray;
      DAE.Ident iter;
      list<Integer> helpVarIndices;
    Integer index;
    list<DAE.ComponentRef> conditions;
    Boolean initialCall;
    case({},vars,idx,_,_)
      equation

      if Flags.isSet(Flags.REDUCE_DAE) then
           Debug.trace("---Replace empty algorithm  \n" );
    end if;
      then ({},vars,idx,{});

  case(DAE.STMT_ASSIGN(ty,e1,e,source)::rest,vars,idx,_,_)
      equation

        if Flags.isSet(Flags.REDUCE_DAE) then
          Debug.trace("---Replace assignment algorithm  \n");
        end if;
    (e2,vars_1,idx2,labels) = addLabelToExp(e,vars,idx,true,reduceList,inVarRepl);
        (rest2,vars_2,idx3,labels2) = addLabelToAlgorithms(rest,vars_1,idx2,reduceList,inVarRepl);

        labels3=listAppend(labels,labels2);
      then
        (DAE.STMT_ASSIGN(ty,e1,e2,source)::rest2,vars_2,idx3,labels3);

    case(DAE.STMT_IF(e,stmtLst,else_,source)::rest,vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("---Replace if algorithm  \n" );
    end if;
       // //Debug.fcall(Flags.CPP,print,"---Replace if algorithm  \n" );
        (stmtLst2,vars_1,idx2,labels) = addLabelToAlgorithms(stmtLst,vars,idx,reduceList,inVarRepl);
        (rest2,vars_2,idx3,labels2) = addLabelToAlgorithms(rest,vars_1,idx2,reduceList,inVarRepl);

        labels3=listAppend(labels,labels2);
      then
        (DAE.STMT_IF(e,stmtLst2,else_,source)::rest2,vars_2,idx3,labels3);

    case(DAE.STMT_FOR(ty,iterIsArray,iter,index,e,stmtLst,source)::rest,vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("---Replace for algorithm  \n" );
    end if;
        (stmtLst2,vars_1,idx2,labels) = addLabelToAlgorithms(stmtLst,vars,idx,reduceList,inVarRepl);
        (rest2,vars_2,idx3,labels2) = addLabelToAlgorithms(rest,vars_1,idx2,reduceList,inVarRepl);
        labels3=listAppend(labels,labels2);
      then
        (DAE.STMT_FOR(ty,iterIsArray,iter,index,e,stmtLst2,source)::rest2,vars_2,idx3,labels3);

    case(DAE.STMT_WHILE(e,stmtLst,source)::rest,vars,idx,_,_)
      equation
        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("---Replace while algorithm  \n" );
    end if;
        (stmtLst2,vars_1,idx2,labels) = addLabelToAlgorithms(stmtLst,vars,idx,reduceList,inVarRepl);
        (rest2,vars_2,idx3,labels2) = addLabelToAlgorithms(rest,vars_1,idx2,reduceList,inVarRepl);
        labels3=listAppend(labels,labels2);
      then
        (DAE.STMT_WHILE(e,stmtLst2,source)::rest2,vars_2,idx3,labels3);

    case(DAE.STMT_WHEN(e,conditions,initialCall,stmtLst,NONE(),source)::rest,vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("---Replace when algorithm without else statement  \n" );
    end if;
        (stmtLst2,vars_1,idx2,labels) = addLabelToAlgorithms(stmtLst,vars,idx,reduceList,inVarRepl);
        (rest2,vars_2,idx3,labels2) = addLabelToAlgorithms(rest,vars_1,idx2,reduceList,inVarRepl);
        labels3=listAppend(labels,labels2);
      then
        (DAE.STMT_WHEN(e,conditions,initialCall,stmtLst2,NONE(),source)::rest2,vars_2,idx3,labels3);

    case(DAE.STMT_WHEN(e,conditions,initialCall,stmtLst,SOME(elseWhen),source)::rest,vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("---Replace when algorithm with else statement  \n" );
    end if;
        (stmtLst2,vars_1,idx2,labels) = addLabelToAlgorithms(stmtLst,vars,idx,reduceList,inVarRepl);
        ({elseWhen2},vars_2,idx3,labels2) = addLabelToAlgorithms({elseWhen},vars_1,idx2,reduceList,inVarRepl);
        (rest2,vars_3,idx4,labels3) = addLabelToAlgorithms(rest,vars_2,idx3,reduceList,inVarRepl);
        labels4=listAppend(labels,labels2);
        labels5=listAppend(labels4,labels3);
      then
        (DAE.STMT_WHEN(e,conditions,initialCall,stmtLst2,SOME(elseWhen2),source)::rest2,vars_3,idx4,labels5);

    case(stmt::rest,vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
        Debug.trace("---Replace other algorithm  \n" );
    end if;
        (rest2,vars_1,idx2,labels) = addLabelToAlgorithms(rest,vars,idx,reduceList,inVarRepl);
      then
        (stmt::rest2,vars_1,idx2,labels);
  end matchcontinue;
end addLabelToAlgorithms;
/* Fatima
protected function addLabelToElse
"helper function for labeling else part"
  input  DAE.Else inElse;
  input  SimCodeVar.SimVars inVarLst;
  input  tuple<Integer,Integer> inIndex;
  input  list <Integer> reduceList;
  input  BackendVarTransform.VariableReplacements inVarRepl;
  output DAE.Else outElse;
  output SimCodeVar.SimVars outVarLst;
  output tuple<Integer,Integer> outIndex;
  output list<String> outStringList;
  algorithm
  (outElse,outVarLst,outIndex,outStringList) := matchcontinue (inElse,inVarLst,inIndex,reduceList,inVarRepl)
    local
      SimCodeVar.SimVars vars,vars_1,vars_2,vars_3;
      tuple <Integer,Integer> idx,idx2,idx3,idx4;
      SimCode.SimEqSystem el,el2;
      list<DAE.Statement> rest,rest2,stmtLst,stmtLst2;
      list<String> labels,labels2,labels3,labels4,labels5;
      DAE.Else else_,else2;
      DAE.Exp e;
    case(DAE.NOELSE(),vars,idx,reduceList,inVarRepl) then (DAE.NOELSE(),vars,idx,{});
    case(DAE.ELSEIF(e,stmtLst,else_),vars,idx,reduceList,inVarRepl)
      equation
        ////Debug.fcall(Flags.CPP,print,"---Replace elseif with else  \n" );
        (stmtLst2,vars_1,idx2,labels) = addLabelToAlgorithms(stmtLst,vars,idx,reduceList,inVarRepl);
        (else2,vars_2,idx3,labels2) = addLabelToElse(else_,vars_1,idx2,reduceList,inVarRepl);
        labels3=listAppend(labels,labels2);
      then
        (DAE.ELSEIF(e,stmtLst2,else2),vars_2,idx3,labels3);
    case(DAE.ELSE(stmtLst),vars,idx,reduceList,inVarRepl)
      equation
        //Debug.fcall(Flags.CPP,print,"---Replace else  \n" );
        (stmtLst2,vars_1,idx2,labels) = addLabelToAlgorithms(stmtLst,vars,idx,reduceList,inVarRepl);
      then
        (DAE.ELSE(stmtLst2),vars_1,idx2,labels) ;
  end matchcontinue;
end addLabelToElse;
*/

protected function addLabelToLinearEquationSystems
"helper function for labeling linear equation systems"
  input  list<tuple<Integer, Integer, SimCode.SimEqSystem>> inLinear;
  input  SimCodeVar.SimVars inVarLst;
  input  tuple<Integer,Integer> inIndex;
  input  list <Integer> reduceList;
  input  BackendVarTransform.VariableReplacements inVarRepl;
  output list<tuple<Integer, Integer, SimCode.SimEqSystem>> outLinear;
  output SimCodeVar.SimVars outVarLst;
  output tuple<Integer,Integer> outIndex;
  output list<String> outStringList;
  algorithm
  (outLinear,outVarLst,outIndex,outStringList) := matchcontinue (inLinear,inVarLst,inIndex,reduceList,inVarRepl)
    local
      SimCodeVar.SimVars vars,vars_1,vars_2,vars_3;
      tuple <Integer,Integer> idx,idx2,idx3,idx4;
      SimCode.SimEqSystem el,el2;
      list<tuple<Integer, Integer, SimCode.SimEqSystem>> rest,rest2;
      Integer i,j;
      list<String> labels,labels2,labels3,labels4,labels5;
    case({},vars,idx,_,_) then ({},vars,idx,{});
    case((i,j,el)::rest,vars,idx,_,_)
      equation
        ({el2},vars_1,idx2,labels) = addLabelToEquations({el},vars,idx,reduceList,inVarRepl);
        (rest2,vars_2,idx3,labels2) = addLabelToLinearEquationSystems(rest,vars_1,idx2,reduceList,inVarRepl);
        labels3=listAppend(labels,labels2);
      then
        ((i,j,el2)::rest2,vars_2,idx3,labels3);
  end matchcontinue;
end addLabelToLinearEquationSystems;


protected function addLabelToExp
"reads the flag REDUCTION_METHOD and calls addLabelToExpForDeletion, addLabelToExpForSubstitution or addLabelToExpForLinearization"

  input DAE.Exp inExp1;
  input SimCodeVar.SimVars inVarLst;
  input tuple<Integer,Integer> inIntdex;
  input Boolean add;
  input list <Integer> reduceList;
  input BackendVarTransform.VariableReplacements inVarRepl;
  output DAE.Exp outExp;
  output SimCodeVar.SimVars outVarLst;
  output tuple<Integer,Integer> outIntdex;
  output list<String> outStringList;
algorithm
  (outExp,outVarLst,outIntdex,outStringList):=
  matchcontinue (inExp1,inVarLst,inIntdex,add,reduceList,inVarRepl)
    local

      DAE.Exp e;
      SimCodeVar.SimVars vars;
      tuple<Integer,Integer> idx;
      list<String> labels;
    case (_,_,_,_,_,_)
      equation
        //case for deletion
        "deletion"=Flags.getConfigString(Flags.REDUCTION_METHOD);
        (e,vars,idx,labels)=addLabelToExpForDeletion(inExp1,inVarLst,inIntdex,add,reduceList);
      then
        (e,vars,idx,labels);
    case (_,_,_,_,_,_)
      equation
        //case for substitution
        "substitution"=Flags.getConfigString(Flags.REDUCTION_METHOD);
        (e,vars,idx,labels,_)=addLabelToExpForSubstitution(inExp1,inVarLst,inIntdex,reduceList,inVarRepl);
      then
        (e,vars,idx,labels);
    case (_,_,_,_,_,_)
      equation
        //case for linearization
        "linearization"=Flags.getConfigString(Flags.REDUCTION_METHOD);
        (e,vars,idx,labels)=addLabelToExpForLinearization(inExp1,inVarLst,inIntdex,reduceList,inVarRepl);
      then
        (e,vars,idx,labels);
  end matchcontinue;
end addLabelToExp;


protected function addLabelToExpForDeletion
"function that adds labels to expressions for the deletion method"

  input DAE.Exp inExp1;
  input SimCodeVar.SimVars inVarLst;
  input tuple<Integer,Integer> inIntdex;
  input Boolean add;
  input list <Integer> reduceList;
  output DAE.Exp outExp;
  output SimCodeVar.SimVars outVarLst;
  output tuple<Integer,Integer> outIntdex;
  output list<String> outStringList;
algorithm
  (outExp,outVarLst,outIntdex,outStringList):=
  matchcontinue (inExp1,inVarLst,inIntdex,add,reduceList)
    local
      DAE.Exp expr,source,target,e1_1,e2_1,e1,e2,e3_1,e3,e_1,r_1,e,r,s;
      DAE.Operator op;
      String name;
      Integer p_1,i_1;
      list<DAE.Exp> expl_1,expl;
      list<Integer> cnt;
      Absyn.Path path,p;
      Boolean c,t;
      Absyn.CodeNode a;

      SimCodeVar.SimVars vars_1,vars_2,vars_3,vars;
      tuple<Integer,Integer> idx,idx1,idx2,idx3,idx4;
      list<String> labels,labels2,labels3,labels4,labels5;
      Real valueR;
      Integer valueI;
      DAE.CallAttributes attr;
     ///Add label to a+b
     case  (e as DAE.BINARY(exp1 = e1,operator = (op as DAE.ADD(ty = _)),exp2 = e2),vars,idx,_,_)

      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to add exp " + ExpressionDump.printExpStr(e) +  "\n");
    end if;

        //labels e_1
        (e1_1,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,true,reduceList);
        //labels e_2
        (e2_1,vars_2,idx3,labels2) = addLabelToExpForDeletion(e2,vars_1,idx2,true,reduceList);
        //creates a label variable and multiplies it with the all expression
        if Flags.getConfigBool(Flags.DISABLE_EXTRA_LABELING) then
        (e3,vars_3, idx4,labels3) = addOneLabel(DAE.BINARY(e1_1,op,e2_1),false,idx3,vars_2,reduceList);
        else
        (e3,vars_3, idx4,labels3) = addOneLabel(DAE.BINARY(e1_1,op,e2_1),add,idx3,vars_2,reduceList);
        end if;
        labels4=listAppend(labels,labels2);
        labels5=listAppend(labels4,labels3);
      then
        (e3,vars_3,idx4,labels5);

      ///Add labe to a-b
     case  (e as DAE.BINARY(exp1 = e1,operator = (op as DAE.SUB(ty = _)),exp2 = e2),vars,idx,_,_)

      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to sub exp " + ExpressionDump.printExpStr(e) +  "\n");
    end if;
        //labels e_1
        (e1_1,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,true,reduceList);
        //labels e_2
        (e2_1,vars_2,idx3,labels2) = addLabelToExpForDeletion(e2,vars_1,idx2,true,reduceList);
        //creates a label variable and multiplies it with the all expression
         if Flags.getConfigBool(Flags.DISABLE_EXTRA_LABELING) then
        (e3,vars_3, idx4,labels3) = addOneLabel(DAE.BINARY(e1_1,op,e2_1),false,idx3,vars_2,reduceList);
        else
        (e3,vars_3, idx4,labels3) = addOneLabel(DAE.BINARY(e1_1,op,e2_1),add,idx3,vars_2,reduceList);
        end if;
        labels4=listAppend(labels,labels2);
        labels5=listAppend(labels4,labels3);
      then
        (e3,vars_3,idx4,labels5);

      ///Add  label to a*b
     case  (e as DAE.BINARY(exp1 = e1,operator = (op as DAE.MUL(ty = _)),exp2 = e2),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to mul exp " + ExpressionDump.printExpStr(e) +  "\n");
    end if;
        //labels e_1
        (e1_1,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,false,reduceList);
        //labels e_2
        (e2_1,vars_2,idx3,labels2) = addLabelToExpForDeletion(e2,vars_1,idx2,false,reduceList);
        //creates a label variable and multiplies it with the all expression
        (e3,vars_3, idx4,labels3) = addOneLabel(DAE.BINARY(e1_1,op,e2_1),add,idx3,vars_2,reduceList);
        labels4=listAppend(labels,labels2);
        labels5=listAppend(labels4,labels3);
      then
        (e3,vars_3,idx4,labels5);

      ///Add label to a/b
     case  (e as DAE.BINARY(exp1 = e1,operator = (op as DAE.DIV(ty = _)),exp2 = e2),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to div exp " + ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to div exp " +& ExpressionDump.printExpStr(e) +&  "\n");

        //labels only the nominator
        (e1_1,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,true,reduceList);
        //(e2_1,vars_2,idx3,labels2) = addLabelToExpForDeletion(e2,vars_1,idx2,true,reduceList);
        //labels3=listAppend(labels,labels2);
      then
        (DAE.BINARY(e1_1,op,e2),vars_1,idx2,labels);

      ///Add  label to a^b
     case  (e as DAE.BINARY(exp1 = e1,operator = (op as DAE.POW(ty = _)),exp2 = e2),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to pow exp " + ExpressionDump.printExpStr(e) +  "\n");
    end if;

        //labels e_1
        (e1_1,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,true,reduceList);
        //labels e_2
        (e2_1,vars_2,idx3,labels2) = addLabelToExpForDeletion(e2,vars_1,idx2,true,reduceList);
        //create a label and multiplies it with the all variable
         if Flags.getConfigBool(Flags.DISABLE_EXTRA_LABELING) then
        (e3,vars_3, idx4,labels3) = addOneLabel(DAE.BINARY(e1_1,op,e2_1),false,idx3,vars_2,reduceList);
         else
        (e3,vars_3, idx4,labels3) = addOneLabel(DAE.BINARY(e1_1,op,e2_1),add,idx3,vars_2,reduceList);
         end if;
        labels4=listAppend(labels,labels2);
        labels5=listAppend(labels4,labels3);
      then
        (e3,vars_3,idx4,labels5);

   ///Add  label to -a
    case (e as DAE.UNARY(operator = op,exp = e1),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to unary exp "+ ExpressionDump.printExpStr(e) +"\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to unary exp "+& ExpressionDump.printExpStr(e) +&"\n");

        (e1_1,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,true,reduceList);

      then
        (DAE.UNARY(op,e1_1),vars_1,idx2,labels);

   ///Add  label to relations
    case (e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Not Implemented: Add label to relation " + ExpressionDump.printExpStr(e)+"\n");
    end if;
      then
        (e,vars,idx,{});

    ///Add label to if expr
    case (e as DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars,idx,_,_)

      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to if exp" + ExpressionDump.printExpStr(e)+"\n");
    end if;
        //labels if-clause
        (e2_1,vars_1,idx2,labels) = addLabelToExpForDeletion(e2,vars,idx,true,reduceList);
        //labels else-clause
        (e3_1,vars_2,idx3,labels2) = addLabelToExpForDeletion(e3,vars_1,idx2,true,reduceList);
        labels3=listAppend(labels,labels2);

      then
        (DAE.IFEXP(e1,e2_1,e3_1),vars_2,idx3,labels3);

    //Add label to pre expr
    case ((e as DAE.CALL(path = Absyn.IDENT(name = "pre"))),vars,idx,_,_)
     equation

          if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("add no label to pre arguments  \n");
    end if;
          //creates a label and multiplies it with the expression
          (e2,vars_1, idx1,labels) = addOneLabel(e,add,idx,vars,reduceList);
      then
        (e2,vars_1,idx1,labels);

     ///Add label to edge operator
     case ((e as DAE.CALL(path = Absyn.IDENT(name = "edge"))),vars,idx,_,_)
      equation

          if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("add no label to edge arguments \n");
    end if;
          //creates a label and multiplies it with the expression
          (e2,vars_1, idx1,labels) = addOneLabel(e,add,idx,vars,reduceList);
      then
          (e2,vars_1,idx1,labels);

       ///Add label to change operator
      case ((e as DAE.CALL(path = Absyn.IDENT(name = "change"))),vars,idx,_,_)
        equation

          if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("add no label to change arguments \n");
    end if;
          //creates a label and multiplies it with the expression
          (e2,vars_1, idx1,labels) = addOneLabel(e,add,idx,vars,reduceList);
        then
          (e2,vars_1,idx1,labels);

      ///Add label to sample operator
      case ((e as DAE.CALL(path = Absyn.IDENT(name = "sample"))),vars,idx,_,_)
        equation

          if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("add no label to sample arguments \n");
    end if;
          //creates a label and multiplies it with the expression
          (e2,vars_1, idx1,labels) = addOneLabel(e,add,idx,vars,reduceList);
        then
          (e2,vars_1,idx1,labels);

       ///Add label to no event operator
      case ((e as DAE.CALL(path = Absyn.IDENT(name = "noEvent"))),vars,idx,_,_)
        equation

          if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("add no label for no event arguments \n");
    end if;
          //creates a label and multiplies it with the expression
          (e2,vars_1, idx1,labels) = addOneLabel(e,add,idx,vars,reduceList);
        then
          (e2,vars_1, idx1,labels);

  case ((e as DAE.CALL(path = Absyn.IDENT(name="max"),expLst = {e1,e2},attr = attr)),vars,idx,_,_)
    equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to max exp " + ExpressionDump.printExpStr(e) +  "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to max exp " +& ExpressionDump.printExpStr(e) +&  "\n");

        //labels e_1
        (e1_1,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,true,reduceList);
        //labels e_2
        (e2_1,vars_2,idx3,labels2) = addLabelToExpForDeletion(e2,vars_1,idx2,true,reduceList);
        //create a label and multiplies it with the all expression
        (e3,vars_3, idx4,labels3) = addOneLabel(DAE.CALL(Absyn.IDENT("max"),{e1_1,e2_1},attr),add,idx3,vars_2,reduceList);
        labels4=listAppend(labels,labels2);
        labels5=listAppend(labels4,labels3);
      then
        (e3,vars_3,idx4,labels5);

  case ((e as DAE.CALL(path = Absyn.IDENT(name="min"),expLst = {e1,e2},attr = attr)),vars,idx,_,_)
    equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to min exp " + ExpressionDump.printExpStr(e) +  "\n");
    end if;
        //labels e_1
        (e1_1,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,true,reduceList);
        //labels e_2
        (e2_1,vars_2,idx3,labels2) = addLabelToExpForDeletion(e2,vars_1,idx2,true,reduceList);
        //creates a label and multiplies it with the all expression
        (e3,vars_3, idx4,labels3) = addOneLabel(DAE.CALL(Absyn.IDENT("min"),{e1_1,e2_1},attr),add,idx3,vars_2,reduceList);
        labels4=listAppend(labels,labels2);
        labels5=listAppend(labels4,labels3);
      then
        (e3,vars_3,idx4,labels5);

    case ((e as DAE.CALL(path = Absyn.IDENT(name="abs"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to abs exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to abs exp "+& ExpressionDump.printExpStr(e) +& "\n");

        //labels e1
        (e2,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,true,reduceList);
        //creates a label and multiplies it with the all expression
          if Flags.getConfigBool(Flags.DISABLE_EXTRA_LABELING) then
          (e3,vars_2, idx3,labels2) = addOneLabel(DAE.CALL(Absyn.IDENT("abs"),{e2},attr),false,idx2,vars_1,reduceList);
          else
        (e3,vars_2, idx3,labels2) = addOneLabel(DAE.CALL(Absyn.IDENT("abs"),{e2},attr),add,idx2,vars_1,reduceList);
         end if;
        labels3=listAppend(labels,labels2);
      then
        (e3,vars_2,idx3,labels3);

    case ((e as DAE.CALL(path = Absyn.IDENT("sqrt"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to sqrt exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;
        //labels the expression under the square root
        (e2,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,true,reduceList);
        //creates a label and multiplies it with the all expression
         if Flags.getConfigBool(Flags.DISABLE_EXTRA_LABELING) then
        (e3,vars_2, idx3,labels2) = addOneLabel(DAE.CALL(Absyn.IDENT("sqrt"),{e2},attr),false,idx2,vars_1,reduceList);
        else
        (e3,vars_2, idx3,labels2) = addOneLabel(DAE.CALL(Absyn.IDENT("sqrt"),{e2},attr),add,idx2,vars_1,reduceList);
         end if;
        labels3=listAppend(labels,labels2);
      then
        (e3,vars_2,idx3,labels3);

    case ((e as DAE.CALL(path = Absyn.IDENT("sin"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to sin exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;
        //labels the expression e_1
        (e2,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,true,reduceList);
      then
        (DAE.CALL(Absyn.IDENT("sin"),{e2},attr),vars_1,idx2,labels);

    case ((e as DAE.CALL(path = Absyn.IDENT("cos"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to cos exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;
        //labels the expression e_1
        (e2,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,true,reduceList);
        //creates a label and multiplies it with the all expression
        (e3,vars_2, idx3,labels2) = addOneLabel(DAE.CALL(Absyn.IDENT("cos"),{e2},attr),add,idx2,vars_1,reduceList);
        labels3=listAppend(labels,labels2);
      then
        (e3,vars_2,idx3,labels3);
    case ((e as DAE.CALL(path = Absyn.IDENT("asin"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to sin exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;
        //labels the expression e_1
        (e2,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,true,reduceList);
      then
        (DAE.CALL(Absyn.IDENT("asin"),{e2},attr),vars_1,idx2,labels);

    case ((e as DAE.CALL(path = Absyn.IDENT("acos"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to cos exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;
        //labels the expression e_1
        (e2,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,true,reduceList);
        //creates a label and multiplies it with the all expression
        (e3,vars_2, idx3,labels2) = addOneLabel(DAE.CALL(Absyn.IDENT("acos"),{e2},attr),add,idx2,vars_1,reduceList);
        labels3=listAppend(labels,labels2);
      then
        (e3,vars_2,idx3,labels3);
    case ((e as DAE.CALL(path = Absyn.IDENT("tan"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to tan exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;
        //labels the expression e_1
        (e1_1,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,true,reduceList);
      then
        (DAE.CALL(Absyn.IDENT("tan"),{e1_1},attr),vars_1,idx2,labels);

   case ((e as DAE.CALL(path = Absyn.IDENT("atan"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to atan exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;
        //labels the expression e_1
        (e1_1,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,true,reduceList);
      then
        (DAE.CALL(Absyn.IDENT("atan"),{e1_1},attr),vars_1,idx2,labels);

   case ((e as DAE.CALL(path = Absyn.IDENT("exp"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to exp exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;
        //labels the expression e_1
        (e2,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,true,reduceList);
        //creates a label and multiplies it with the all expression
        (e3,vars_2, idx3,labels2) = addOneLabel(DAE.CALL(Absyn.IDENT("exp"),{e2},attr),add,idx2,vars_1,reduceList);
        labels3=listAppend(labels,labels2);
      then
        (e3,vars_2,idx3,labels3);

  case ((e as DAE.CALL(path = Absyn.IDENT(name="div"),expLst = {e1,e2},attr = attr)),vars,idx,_,_)
    equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to div exp " + ExpressionDump.printExpStr(e) +  "\n");
    end if;
        //labels only the nominator of a division expression
        (e1_1,vars_1,idx2,labels) = addLabelToExpForDeletion(e1,vars,idx,true,reduceList);
        //(e2_1,vars_2,idx3,labels2) = addLabelToExpForDeletion(e2,vars_1,idx2,false,reduceList);
        //labels3=listAppend(labels,labels2);
      then
        (DAE.CALL(Absyn.IDENT("div"),{e1_1,e2},attr),vars_1,idx2,labels);

      ///Add no label to all other call functions
    case ((e as DAE.CALL(path = path,expLst = expl,attr = attr)),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add no label to other call function "+ ExpressionDump.printExpStr(e) + "\n");
    end if;
      then
        (DAE.CALL(path,expl,attr),vars,idx,{});

       ///Add label to real const 0.0
     case (DAE.RCONST(real = valueR),vars,idx,_,_)
       equation
         equality(valueR = 0.0);

         if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add no label to const 0.0 \n");
    end if;
       then
        (DAE.RCONST(0.0),vars,idx,{});

     ///Add label to real const
     case ((e as DAE.RCONST(_)),vars,idx,_,_)
       equation
          if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to real const variable " + ExpressionDump.printExpStr(e) +  "\n");
    end if;
          (e2,vars_1, idx1,labels) = addOneLabel(e,add,idx,vars,reduceList);
       then
        (e2,vars_1,idx1,labels);

       ///Add label to int const 0
      case ( DAE.ICONST(integer=valueI),vars,idx,_,_)
      equation
        equality(valueI = 0);

          if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add no label to const 0 \n");
    end if;
        then
         (DAE.ICONST(0),vars,idx,{});

      ///Add label to int const
      case ((e as DAE.ICONST(_)),vars,idx,_,_)
      equation
           if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to integer const variable " + ExpressionDump.printExpStr(e) +  "\n");
    end if;
          (e2,vars_1, idx1,labels) = addOneLabel(e,add,idx,vars,reduceList);
       then
        (e2,vars_1,idx1,labels);

       ///Add label to string const
      case ((e as DAE.SCONST(_)),vars,idx,_,_)
      equation
        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add no label to string const variable " + ExpressionDump.printExpStr(e) + "\n");
    end if;
      then
        (e,vars,idx,{});

      ///Add label to bool const
      case ((e as DAE.BCONST(_)),vars,idx,_,_)

      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add no label to boolean const variable " + ExpressionDump.printExpStr(e) + "\n");
    end if;
      then
        (e,vars,idx,{});

     ///Add label string const values, variables, parameters
     case(e as DAE.CREF(_,DAE.T_STRING(_)),vars,idx,_,_)
        equation
          if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add no label to string variable " + ExpressionDump.printExpStr(e) +  "\n");
    end if;
       then
        (e,vars,idx,{});
     ///Add label string const values, variables, parameters
     case(e as DAE.CREF(_,DAE.T_BOOL(_)),vars,idx,_,_)
        equation
          if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add no label to boolean variable " + ExpressionDump.printExpStr(e) +  "\n");
    end if;
       then
        (e,vars,idx,{});
     ///Add label const values, variables, parameters
     case(e as DAE.CREF(_,_),vars,idx,_,_)

        equation

          if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to variable " + ExpressionDump.printExpStr(e) + "\n");
    end if;
          (e2,vars_1, idx1,labels) = addOneLabel(e,add,idx,vars,reduceList);
       then
        (e2,vars_1,idx1,labels);

    ///Add label to all other expressions
     case(e,vars,idx,_,_)
       equation

         if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to unknown expression " + ExpressionDump.printExpStr(e) + "\n");
    end if;
       then
         (e,vars,idx,{});

  end matchcontinue;
end addLabelToExpForDeletion;

/*
protected function addLabelToExpList
"function that adds labels to expression lists"
  input list<Expression.Exp> inExpLst;
  input SimCodeVar.SimVars inVarLst;
  input tuple<Integer,Integer> inIndex;
  input list<Integer> reduceList;
  output list<Expression.Exp>  outExpLst;
  output SimCodeVar.SimVars outVarLst;
  output tuple<Integer,Integer> outIndex;
  output list<String> outStringList;
algorithm
  (outExpLst,outVarLst,outIndex,outStringList):=
  matchcontinue (inExpLst,inVarLst,inIndex,reduceList)
    local
      Expression.Exp e,e_1,e_2,e1;
      tuple<Integer,Integer> idx1,idx2,idx3;
      list<Expression.Exp> er,er2;
      SimCodeVar.SimVars vars,vars_1,vars_2;
      list<String> labels,labels2,labels3;
      BackendVarTransform.VariableReplacements repl;
    case ({},vars,idx1,reduceList) then ({},vars,idx1,{});
    case ((e1 :: er),vars,idx1,reduceList)
      equation
        repl=BackendVarTransform.emptyReplacements();
        (e_1,vars_1,idx2,labels) = addLabelToExp(e1,vars,idx1,true,reduceList,repl);
        (er2,vars_2,idx3,labels2) = addLabelToExpList(er, vars_1, idx2,reduceList);
        labels3=listAppend(labels,labels2);
      then
        (e_1::er2,vars_2,idx3,labels3);
  end matchcontinue;
end addLabelToExpList;
*/

protected function addOneLabel
"if GENERATE_LABELED_SIMCODE=true: calls createLabelVar and then multiplies it with the corresponding expression;
if REDUCE_TERMS=true: multiplies a term by 0, if it is on the reduceList, otherwise multiplies it by 1 "
  input DAE.Exp inExp1;
  input Boolean add;
  input tuple<Integer,Integer> inIndex;
  input SimCodeVar.SimVars inVarLst;
  input list<Integer> reduceList;
  output DAE.Exp outExp;
  output SimCodeVar.SimVars outVarLst;
  output tuple<Integer,Integer> outIndex;
  output list<String> outStringList;
algorithm
  (outExp,outVarLst,outIndex,outStringList):=
  matchcontinue (inExp1,add,inIndex,inVarLst,reduceList)
      local
        DAE.Exp e,e2;
        String name,name1;
        SimCodeVar.SimVars vars,vars_1;
        Integer i,p,p_1,i_1;
     case (e,true,(i,p),vars,_)
       equation
         //case reduce terms
         true = Flags.getConfigBool(Flags.REDUCE_TERMS);
         //the number of the term is on the reduceList
         _ = List.getMember(i, reduceList);
         //multiplies the term by 0
         e2=Expression.expMul(DAE.RCONST(0.0),e);
         //increases the number of (invisible) labels
         i_1=i+1;
       then
         (e2,vars,(i_1,p),{});
     case (e,true,(i,p),vars,_)
       equation
         //case reduce terms
         true = Flags.getConfigBool(Flags.REDUCE_TERMS);
         //multiplies the term by 1
         e2=Expression.expMul(DAE.RCONST(1.0),e);
         //increases the number of (invisible) labels
         i_1=i+1;
       then
         (e2,vars,(i_1,p),{});
     //case for labeling terms
     case  (e,true,(i,p),vars,_)
      equation
        //creates a label variable
         (vars_1,name)= createLabelVar(vars,p,i);
          name1=stringAppend(name,"_1");
          //multiplies the label with the expression
          e2=multiply(e,name1);
          //increases the number of parameters by 2 (label_1 and label_2) and the number of labels by 1
          p_1=p+2;
          i_1=i+1;
      then
        (e2,vars_1,(i_1,p_1),{name});
    case  (e,false,(i,p),vars,_)
      then
        (e,vars,(i,p),{});
 end matchcontinue;
end addOneLabel;


protected function addLabelToExpForLinearization
"function that adds labels to expressions for linearization"

  input DAE.Exp inExp1;
  input SimCodeVar.SimVars inVarLst;
  input tuple<Integer,Integer> inIndex;
  input list<Integer> reduceList;
  input BackendVarTransform.VariableReplacements inVarRepl;

  output DAE.Exp outExp;
  output SimCodeVar.SimVars outVarLst;
  output tuple<Integer,Integer> outIndex;
  output list<String> outStringList;
algorithm
  (outExp,outVarLst,outIndex,outStringList):=
  matchcontinue (inExp1,inVarLst,inIndex,reduceList,inVarRepl)
    local

      DAE.Exp e,e1,e2,e3,e4,e5,e6;
      DAE.Operator op;
      SimCodeVar.SimVars vars,vars1,vars2;
      tuple<Integer,Integer> idx,idx1,idx2;
      list<String> labels,labels1,labels2;
      DAE.CallAttributes attr;
      DAE.ComponentRef cr;
      DAE.Type tp;
    //Linearize x^a
    case (e as DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = tp),exp2 = e2),vars,idx,_,_)
      equation
        true = Expression.expHasCrefs(e1);
        false = Expression.expHasCrefs(e2);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to pow exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to pow exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e3,vars1,idx1,labels)=addLabelToExpForLinearization(e1,vars,idx,reduceList,inVarRepl);
      then
        (DAE.BINARY(e3,DAE.POW(tp),e2),vars1,idx1,labels);
    //Linearize a^x
    case (e as DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = tp),exp2 = e2),vars,idx,_,_)
      equation
        false = Expression.expHasCrefs(e1);
        true = Expression.expHasCrefs(e2);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to pow exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to pow exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e3,vars1,idx1,labels)=addLabelToExpForLinearization(e2,vars,idx,reduceList,inVarRepl);
        e4=DAE.BINARY(e1,DAE.POW(tp),e3);
        e5=linearizeExp(e4,e3,vars,inVarRepl);
        (e6,vars2,idx2,labels1)=addTwoLabels(e4,e5,true,vars1,idx1,reduceList);
        labels2=listAppend(labels,labels1);
      then
        (e6,vars2,idx2,labels2);
    //Linearize a+b,a-b,a*b,a/b
    case  (e as DAE.BINARY(exp1 = e1,operator = op ,exp2 = e2),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to binary exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to binary exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e3,vars1,idx1,labels)=addLabelToExpForLinearization(e1,vars,idx,reduceList,inVarRepl);
        (e4,vars2,idx2,labels1)=addLabelToExpForLinearization(e2,vars1,idx1,reduceList,inVarRepl);
        labels2=listAppend(labels,labels1);
      then
        (DAE.BINARY(e3,op,e4),vars2,idx2,labels2);
    //Linearize -a
    case (e as DAE.UNARY(operator = op,exp = e1),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to unary exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to unary exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels)=addLabelToExpForLinearization(e1,vars,idx,reduceList,inVarRepl);
      then
        (DAE.UNARY(op,e2),vars1,idx1,labels);
    //Linearize if-expressions
    case (e as DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to if exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to if exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e4,vars1,idx1,labels) = addLabelToExpForLinearization(e2,vars,idx,reduceList,inVarRepl);
        (e5,vars2,idx2,labels1) = addLabelToExpForLinearization(e3,vars1,idx1,reduceList,inVarRepl);
        labels2=listAppend(labels,labels1);
      then
        (DAE.IFEXP(e1,e4,e5),vars2,idx2,labels2);
   //Linearize sin x
    case  (e as DAE.CALL(path = Absyn.IDENT("sin"),expLst = {e1},attr = attr),vars,idx,_,_)
      equation
        //check that the expression contains variables -> otherwise does not make sense to linearize the expression
        true = Expression.expHasCrefs(e);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to sin exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to sin exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels)=addLabelToExpForLinearization(e1,vars,idx,reduceList,inVarRepl);
        e3=DAE.CALL(Absyn.IDENT("sin"),{e2},attr);
        e4=linearizeExp(e3,e2,vars,inVarRepl);
        (e5,vars2,idx2,labels1)=addTwoLabels(e3,e4,true,vars1,idx1,reduceList);
        labels2=listAppend(labels,labels1);
      then
        (e5,vars2,idx2,labels2);
    //Linearize cos x
    case  (e as DAE.CALL(path = Absyn.IDENT("cos"),expLst = {e1},attr = attr),vars,idx,_,_)
      equation
        //check that the expression contains variables -> otherwise does not make sense to linearize the expression
        true = Expression.expHasCrefs(e);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to cos exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to cos exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels)=addLabelToExpForLinearization(e1,vars,idx,reduceList,inVarRepl);
        e3=DAE.CALL(Absyn.IDENT("cos"),{e2},attr);
        e4=linearizeExp(e3,e2,vars,inVarRepl);
        (e5,vars2,idx2,labels1)=addTwoLabels(e3,e4,true,vars1,idx1,reduceList);
        labels2=listAppend(labels,labels1);
      then
        (e5,vars2,idx2,labels2);
    //Linearize tan x
    case  (e as DAE.CALL(path = Absyn.IDENT("tan"),expLst = {e1},attr = attr),vars,idx,_,_)
      equation
        //check that the expression contains variables -> otherwise does not make sense to linearize the expression
        true = Expression.expHasCrefs(e);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to tan exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to tan exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels)=addLabelToExpForLinearization(e1,vars,idx,reduceList,inVarRepl);
        e3=DAE.CALL(Absyn.IDENT("tan"),{e2},attr);
        e4=linearizeExp(e3,e2,vars,inVarRepl);
        (e5,vars2,idx2,labels1)=addTwoLabels(e3,e4,true,vars1,idx1,reduceList);
        labels2=listAppend(labels,labels1);
      then
        (e5,vars2,idx2,labels2);
    //Linearize asin x
    case  (e as DAE.CALL(path = Absyn.IDENT("asin"),expLst = {e1},attr = attr),vars,idx,_,_)
      equation
        //check that the expression contains variables -> otherwise does not make sense to linearize the expression
        true = Expression.expHasCrefs(e);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to asin exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to asin exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels)=addLabelToExpForLinearization(e1,vars,idx,reduceList,inVarRepl);
        e3=DAE.CALL(Absyn.IDENT("asin"),{e2},attr);
        e4=linearizeExp(e3,e2,vars,inVarRepl);
        (e5,vars2,idx2,labels1)=addTwoLabels(e3,e4,true,vars1,idx1,reduceList);
        labels2=listAppend(labels,labels1);
      then
        (e5,vars2,idx2,labels2);
    //Linearize acos x
    case  (e as DAE.CALL(path = Absyn.IDENT("acos"),expLst = {e1},attr = attr),vars,idx,_,_)
      equation
        //check that the expression contains variables -> otherwise does not make sense to linearize the expression
        true = Expression.expHasCrefs(e);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to acos exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to acos exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels)=addLabelToExpForLinearization(e1,vars,idx,reduceList,inVarRepl);
        e3=DAE.CALL(Absyn.IDENT("acos"),{e2},attr);
        e4=linearizeExp(e3,e2,vars,inVarRepl);
        (e5,vars2,idx2,labels1)=addTwoLabels(e3,e4,true,vars1,idx1,reduceList);
        labels2=listAppend(labels,labels1);
      then
        (e5,vars2,idx2,labels2);
    //Linearize atan x
    case  (e as DAE.CALL(path = Absyn.IDENT("atan"),expLst = {e1},attr = attr),vars,idx,_,_)
      equation
        //check that the expression contains variables -> otherwise does not make sense to linearize the expression
        true = Expression.expHasCrefs(e);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to atan exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to atan exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels)=addLabelToExpForLinearization(e1,vars,idx,reduceList,inVarRepl);
        e3=DAE.CALL(Absyn.IDENT("atan"),{e2},attr);
        e4=linearizeExp(e3,e2,vars,inVarRepl);
        (e5,vars2,idx2,labels1)=addTwoLabels(e3,e4,true,vars1,idx1,reduceList);
        labels2=listAppend(labels,labels1);
      then
        (e5,vars2,idx2,labels2);
    //Linearize e^x
    case  (e as DAE.CALL(path = Absyn.IDENT("exp"),expLst = {e1},attr = attr),vars,idx,_,_)
      equation
        //check that the expression contains variables -> otherwise does not make sense to linearize the expression
        true = Expression.expHasCrefs(e);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to exp exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to exp exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels)=addLabelToExpForLinearization(e1,vars,idx,reduceList,inVarRepl);
        e3=DAE.CALL(Absyn.IDENT("exp"),{e2},attr);
        e4=linearizeExp(e3,e2,vars,inVarRepl);
        (e5,vars2,idx2,labels1)=addTwoLabels(e3,e4,true,vars1,idx1,reduceList);
        labels2=listAppend(labels,labels1);
      then
        (e5,vars2,idx2,labels2);
    //Linearize log x
    case  (e as DAE.CALL(path = Absyn.IDENT("log"),expLst = {e1},attr = attr),vars,idx,_,_)
      equation
        //check that the expression contains variables -> otherwise does not make sense to linearize the expression
        true = Expression.expHasCrefs(e);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to log exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to log exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels)=addLabelToExpForLinearization(e1,vars,idx,reduceList,inVarRepl);
        e3=DAE.CALL(Absyn.IDENT("log"),{e2},attr);
        e4=linearizeExp(e3,e2,vars,inVarRepl);
        (e5,vars2,idx2,labels1)=addTwoLabels(e3,e4,true,vars1,idx1,reduceList);
        labels2=listAppend(labels,labels1);
      then
        (e5,vars2,idx2,labels2);
    //Linearize square root
    case  (e as DAE.CALL(path = Absyn.IDENT("sqrt"),expLst = {e1},attr = attr),vars,idx,_,_)
      equation
        //check that the expression contains variables -> otherwise does not make sense to linearize the expression
        true = Expression.expHasCrefs(e);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to sqrt exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to sqrt exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels)=addLabelToExpForLinearization(e1,vars,idx,reduceList,inVarRepl);
        e3=DAE.CALL(Absyn.IDENT("sqrt"),{e2},attr);
        e4=linearizeExp(e3,e2,vars,inVarRepl);
        (e5,vars2,idx2,labels1)=addTwoLabels(e3,e4,true,vars1,idx1,reduceList);
        labels2=listAppend(labels,labels1);
      then
        (e5,vars2,idx2,labels2);
    case (e,vars,idx,_,_)
      then (e,vars,idx,{});
  end matchcontinue;
end addLabelToExpForLinearization;


protected function addTwoLabels
"if GENERATE_LABELED_SIMCODE=true: calls createLabelVar and then multiplies label_1 with the original expression and label_2 with
the alternative expression (substitution: average value, linearization: linearized expression);
if REDUCE_TERMS=true: 1) label is on the reduceList: multiplies 0 with the original expression and 1 with
the alternative expression (substitution: average value, linearization: linearized expression);
2) label is not on the reduceList: multiplies 1 with the original expression and 0 with
the alternative expression (substitution: average value, linearization: linearized expression);"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input Boolean label;
  input SimCodeVar.SimVars inVarLst;
  input tuple<Integer,Integer> inIndex;
  input list<Integer> reduceList;
  output DAE.Exp outExp;
  output SimCodeVar.SimVars outVarLst;
  output tuple<Integer,Integer> outIndex;
  output list<String> outStringList;
algorithm
  (outExp,outVarLst,outIndex,outStringList):=
  matchcontinue (inExp1,inExp2,label,inVarLst,inIndex,reduceList)
    local
      DAE.Exp e1,e2,e3,e4,e5;
      Integer i,i_1,p,p_1;
      SimCodeVar.SimVars vars,vars_1;
      tuple<Integer,Integer> idx;
      String name,name1,name2;
    //case for reduce terms
    case  (e1,e2,true,vars,(i,p),_)
      equation
        true = Flags.getConfigBool(Flags.REDUCE_TERMS);
        _ = List.getMember(i,reduceList);
        e3=Expression.expMul(DAE.RCONST(0.0),e1);
        e4=Expression.expMul(DAE.RCONST(1.0),e2);
        e5=Expression.expAdd(e3,e4);
        i_1=i+1;
      then
        (e5,vars,(i_1,p),{});
    //case for reduce terms
    case  (e1,e2,true,vars,(i,p),_)
      equation
        true = Flags.getConfigBool(Flags.REDUCE_TERMS);
        e3=Expression.expMul(DAE.RCONST(1.0),e1);
        e4=Expression.expMul(DAE.RCONST(0.0),e2);
        e5=Expression.expAdd(e3,e4);
        i_1=i+1;
      then
        (e5,vars,(i_1,p),{});
    //case for generating labels
    case  (e1,e2,true,vars,(i,p),_)
      equation
        (vars_1,name)= createLabelVar(vars,p,i);
        name1=stringAppend(name,"_1");
        name2=stringAppend(name,"_2");
        e3=multiply(e1,name1);
        e4=multiply(e2,name2);
        e5=Expression.expAdd(e3,e4);
        p_1=p+2;
        i_1=i+1;
      then
        (e5,vars_1,(i_1,p_1),{name});
    case  (e1,e2,false,vars,(i,p),_)
      then
        (e1,vars,(i,p),{});
 end matchcontinue;
end addTwoLabels;


protected function linearizeExp
"function that linearizes an expression"

  input DAE.Exp inExp;
  input DAE.Exp source;
  input SimCodeVar.SimVars inVarLst;
  input BackendVarTransform.VariableReplacements inVarRepl;
  output DAE.Exp outExp;
algorithm
  outExp:=matchcontinue(inExp,source,inVarLst,inVarRepl)
    local
      DAE.Exp e,e1,e2,e3,e4,e5,e6,tmpExp,replExp;
      DAE.ComponentRef tmp;
      SimCodeVar.SimVars vars;
      BackendVarTransform.VariableReplacements repl;
    case  (e1,e2,vars,repl)
      equation
        //replaced variable
        (replExp,_)=BackendVarTransform.replaceExp(e2,repl,NONE());
        //first summand
        ((e,_))=Expression.replaceExp(e1,e2,replExp);
        //make a variable for derivation
        tmp=ComponentReference.makeCrefIdent("linVar",DAE.T_UNKNOWN_DEFAULT,{});
        tmpExp=Expression.crefExp(tmp);
        //second summand
        ((e3,_))=Expression.replaceExp(e1,e2,tmpExp);
        e4=Differentiate.differentiateExpSolve(e3,tmp,NONE());
        ((e5,_))=Expression.replaceExp(e4,tmpExp,replExp);
        //first+second
        e6=Expression.expAdd(e,Expression.expMul(e5,Expression.expSub(e2,replExp)));
      then
        e6;
  end matchcontinue;
end linearizeExp;

protected function addLabelToExpForSubstitution
"function that adds labels to expressions for substitution"

  input DAE.Exp inExp1;

  input SimCodeVar.SimVars inVarLst;
  input tuple<Integer,Integer> inIndex;
  input list<Integer> reduceList;
  input BackendVarTransform.VariableReplacements inVarRepl;

  output DAE.Exp outExp;

  output SimCodeVar.SimVars outVarLst;
  output tuple<Integer,Integer> outIndex;
  output list<String> outStringList;
  output Boolean substitute;
algorithm
  (outExp,outVarLst,outIndex,outStringList,substitute):=
  matchcontinue (inExp1,inVarLst,inIndex,reduceList,inVarRepl)
    local

      DAE.Exp e,ex,e1,e2,e3,e4,e5,e6;
      DAE.Operator op;

      SimCodeVar.SimVars vars,vars1,vars2,vars3;
      tuple<Integer,Integer> idx,idx1,idx2,idx3;
      list<String> labels,labels1,labels2,labels3,labels4;
      list<DAE.Exp> expLst,expLst2;
      DAE.CallAttributes attr;
      DAE.ComponentRef cr;
      DAE.Type tp;
      Absyn.Path path;
      Boolean subs,subs1,subs2,subs3,subs4;
    //Substitute binary expressions
    case  (e as DAE.BINARY(exp1 = e1,operator = op ,exp2 = e2),vars,idx,_,_)
      equation
        (ex,true)=substituteExp(e,inVarRepl);
        (e3,vars1,idx1,labels,subs1)=addLabelToExpForSubstitution(e1,vars,idx,reduceList,inVarRepl);
        (e4,vars2,idx2,labels1,subs2)=addLabelToExpForSubstitution(e2,vars1,idx1,reduceList,inVarRepl);
        //a binary expression should be labeled only if its both members contain labels
        subs3=boolAnd(subs1,subs2);
        (e5,vars3,idx3,labels2)=addTwoLabels(DAE.BINARY(e3,op,e4),ex,subs3,vars2,idx2,reduceList);
        //subs4 shows if an expressions contains labels
        subs4=boolOr(subs1,subs2);
        labels3=listAppend(labels,labels1);
        labels4=listAppend(labels3,labels2);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to binary exp " + ExpressionDump.printExpStr(e) +  "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to binary exp " +& ExpressionDump.printExpStr(e) +&  "\n");

      then
        (e5,vars3,idx3,labels4,subs4);
    //Substitute -a
    case (e as DAE.UNARY(operator = op,exp = e1),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to unary exp " + ExpressionDump.printExpStr(e) +  "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to unary exp " +& ExpressionDump.printExpStr(e) +&  "\n");

        (e2,vars1,idx1,labels,subs)=addLabelToExpForSubstitution(e1,vars,idx,reduceList,inVarRepl);
      then
        (DAE.UNARY(op,e2),vars1,idx1,labels,subs);
    //Substitute if-expressions
    case (e as DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars,idx,_,_)
      equation

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to if exp " + ExpressionDump.printExpStr(e) +  "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to if exp " +& ExpressionDump.printExpStr(e) +&  "\n");

        (e4,vars1,idx1,labels,_) = addLabelToExpForSubstitution(e2,vars,idx,reduceList,inVarRepl);
        (e5,vars2,idx2,labels1,_) = addLabelToExpForSubstitution(e3,vars1,idx1,reduceList,inVarRepl);
        labels2=listAppend(labels,labels1);
      then
        (DAE.IFEXP(e1,e4,e5),vars2,idx2,labels2,true);
  //Substitute max-expressions
  case (e as (DAE.CALL(path = Absyn.IDENT(name="max"),expLst = {e1,e2},attr = attr)),vars,idx,_,_)
    equation
        (ex,true)=substituteExp(e,inVarRepl);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to max exp " + ExpressionDump.printExpStr(e) +  "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to max exp " +& ExpressionDump.printExpStr(e) +&  "\n");

        (e3,vars1,idx1,labels,subs1)=addLabelToExpForSubstitution(e1,vars,idx,reduceList,inVarRepl);
        (e4,vars2,idx2,labels1,subs2)=addLabelToExpForSubstitution(e2,vars1,idx1,reduceList,inVarRepl);
        subs3=boolAnd(subs1,subs2);
        (e5,vars3,idx3,labels2)=addTwoLabels(DAE.CALL(Absyn.IDENT("max"),{e3,e4},attr),ex,subs3,vars2,idx2,reduceList);
        subs4=boolOr(subs1,subs2);
        labels3=listAppend(labels,labels1);
        labels4=listAppend(labels3,labels2);
      then
        (e5,vars3,idx3,labels4,subs4);
  //Substitute min-expressions
  case (e as (DAE.CALL(path = Absyn.IDENT(name="min"),expLst = {e1,e2},attr = attr)),vars,idx,_,_)
    equation

        (ex,true)=substituteExp(e,inVarRepl);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to min exp " + ExpressionDump.printExpStr(e) +  "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to min exp " +& ExpressionDump.printExpStr(e) +&  "\n");

        (e3,vars1,idx1,labels,subs1)=addLabelToExpForSubstitution(e1,vars,idx,reduceList,inVarRepl);
        (e4,vars2,idx2,labels1,subs2)=addLabelToExpForSubstitution(e2,vars1,idx1,reduceList,inVarRepl);
        subs3=boolAnd(subs1,subs2);
        (e5,vars3,idx3,labels2)=addTwoLabels(DAE.CALL(Absyn.IDENT("min"),{e3,e4},attr),ex,subs3,vars2,idx2,reduceList);
        subs4=boolOr(subs1,subs2);
        labels3=listAppend(labels,labels1);
        labels4=listAppend(labels3,labels2);
      then
        (e5,vars3,idx3,labels4,subs4);
    //Substitute absolute value expressions
    case (e as (DAE.CALL(path = Absyn.IDENT(name="abs"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        (ex,true)=substituteExp(e,inVarRepl);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to abs exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to abs exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels,subs) = addLabelToExpForSubstitution(e1,vars,idx,reduceList,inVarRepl);
        //(e3,vars2,idx2,labels2)=addTwoLabels(DAE.CALL(Absyn.IDENT("abs"),{e2},attr),e,vars1,idx1,reduceList);
        //labels3=listAppend(labels,labels2);
      then
        (e2,vars1,idx1,labels,subs);
    //Substitute square root expressions
    case (e as (DAE.CALL(path = Absyn.IDENT("sqrt"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        (ex,true)=substituteExp(e,inVarRepl);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to sqrt exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to sqrt exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels,subs) = addLabelToExpForSubstitution(e1,vars,idx,reduceList,inVarRepl);
        //(e3,vars2,idx2,labels2)=addTwoLabels(DAE.CALL(Absyn.IDENT("sqrt"),{e2},attr),e,vars1,idx1,reduceList);
        //labels3=listAppend(labels,labels2);
      then
        (e2,vars1,idx1,labels,subs);
    //Substitute sin expressions
    case (e as(DAE.CALL(path = Absyn.IDENT("sin"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        (ex,true)=substituteExp(e,inVarRepl);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to sin exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to sin exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels,subs) = addLabelToExpForSubstitution(e1,vars,idx,reduceList,inVarRepl);
        //(e3,vars2,idx2,labels2)=addTwoLabels(DAE.CALL(Absyn.IDENT("sin"),{e2},attr),e,vars1,idx1,reduceList);
        //labels3=listAppend(labels,labels2);
      then
        (e2,vars1,idx1,labels,subs);
    //Substitute cos expressions
    case (e as (DAE.CALL(path = Absyn.IDENT("cos"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        (ex,true)=substituteExp(e,inVarRepl);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to cos exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to cos exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels,subs) = addLabelToExpForSubstitution(e1,vars,idx,reduceList,inVarRepl);
        //(e3,vars2,idx2,labels2)=addTwoLabels(DAE.CALL(Absyn.IDENT("cos"),{e2},attr),e,vars1,idx1,reduceList);
        //labels3=listAppend(labels,labels2);
      then
        (e2,vars1,idx1,labels,subs);
    //Substitute tan expressions
    case (e as (DAE.CALL(path = Absyn.IDENT("tan"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        (ex,true)=substituteExp(e,inVarRepl);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to tan exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to tan exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels,subs) = addLabelToExpForSubstitution(e1,vars,idx,reduceList,inVarRepl);
        //(e3,vars2,idx2,labels2)=addTwoLabels(DAE.CALL(Absyn.IDENT("tan"),{e2},attr),e,vars1,idx1,reduceList);
        //labels3=listAppend(labels,labels2);
      then
        (e2,vars1,idx1,labels,subs);
        //Substitute asin expressions
    case (e as (DAE.CALL(path = Absyn.IDENT("asin"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        (ex,true)=substituteExp(e,inVarRepl);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to asin exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to asin exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels,subs) = addLabelToExpForSubstitution(e1,vars,idx,reduceList,inVarRepl);
        //(e3,vars2,idx2,labels2)=addTwoLabels(DAE.CALL(Absyn.IDENT("asin"),{e2},attr),e,vars1,idx1,reduceList);
        //labels3=listAppend(labels,labels2);
      then
        (e2,vars1,idx1,labels,subs);
    //Substitute acos expressions
    case (e as (DAE.CALL(path = Absyn.IDENT("acos"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        (ex,true)=substituteExp(e,inVarRepl);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to acos exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to acos exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels,subs) = addLabelToExpForSubstitution(e1,vars,idx,reduceList,inVarRepl);
        //(e3,vars2,idx2,labels2)=addTwoLabels(DAE.CALL(Absyn.IDENT("acos"),{e2},attr),e,vars1,idx1,reduceList);
        //labels3=listAppend(labels,labels2);
      then
        (e2,vars1,idx1,labels,subs);
   //Substitute atan expressions
   case (e as (DAE.CALL(path = Absyn.IDENT("atan"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        (ex,true)=substituteExp(e,inVarRepl);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to atan exp "+ ExpressionDump.printExpStr(e) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to atan exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels,subs) = addLabelToExpForSubstitution(e1,vars,idx,reduceList,inVarRepl);
        //(e3,vars2,idx2,labels2)=addTwoLabels(DAE.CALL(Absyn.IDENT("atan"),{e2},attr),e,vars1,idx1,reduceList);
        //labels3=listAppend(labels,labels2);
      then
        (e2,vars1,idx1,labels,subs);
   //Substitute e^x
   case (e as (DAE.CALL(path = Absyn.IDENT("exp"),expLst = {e1},attr = attr)),vars,idx,_,_)
      equation

        (ex,true)=substituteExp(e,inVarRepl);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to exp exp "+ ExpressionDump.printExpStr(ex) + "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to exp exp "+& ExpressionDump.printExpStr(e) +& "\n");

        (e2,vars1,idx1,labels,subs) = addLabelToExpForSubstitution(e1,vars,idx,reduceList,inVarRepl);
        //(e3,vars2,idx2,labels2)=addTwoLabels(DAE.CALL(Absyn.IDENT("exp"),{e2},attr),e,vars1,idx1,reduceList);
        //labels3=listAppend(labels,labels2);
      then
        (e2,vars1,idx1,labels,subs);
  //Substitute div expression
  case (e as (DAE.CALL(path = Absyn.IDENT(name="div"),expLst = {e1,e2},attr = attr)),vars,idx,_,_)
    equation

        (ex,true)=substituteExp(e,inVarRepl);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to div exp " + ExpressionDump.printExpStr(e) +  "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to div exp " +& ExpressionDump.printExpStr(e) +&  "\n");

        (e3,vars1,idx1,labels,subs1)=addLabelToExpForSubstitution(e1,vars,idx,reduceList,inVarRepl);
        (e4,vars2,idx2,labels1,subs2)=addLabelToExpForSubstitution(e2,vars1,idx1,reduceList,inVarRepl);
        subs3=boolAnd(subs1,subs2);
        (e5,vars3,idx3,labels2)=addTwoLabels(DAE.CALL(Absyn.IDENT("div"),{e3,e4},attr),ex,subs3,vars2,idx2,reduceList);
        subs4=boolOr(subs1,subs2);
        labels3=listAppend(labels,labels1);
        labels4=listAppend(labels3,labels2);
      then
        (e5,vars3,idx3,labels4,subs4);

    //Substitute call exp
    ///case  (e as DAE.CALL(path = path,expLst = expLst,attr = attr),vars,idx,reduceList,inVarRepl)
      //equation
       // //Debug.fcall(Flags.CPP,print,"Add label to call exp " +& ExpressionDump.printExpStr(e) +&  "\n");
       // (expLst2,vars1,idx1,labels,subs)=addLabelToExpListForSubstitution(expLst,vars,idx,reduceList,inVarRepl);
     // then
       /// (DAE.CALL(path,expLst2,attr,subs),vars1,idx1,labels);
    //Substitute integer algebraic, state and derivative variables
    case  (e as DAE.CREF(_,DAE.T_INTEGER(_)),vars,idx,_,_)
      equation

        (e1,true)=substituteExp(e,inVarRepl);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to integer variable " + ExpressionDump.printExpStr(e) +  "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to integer variable " +& ExpressionDump.printExpStr(e) +&  "\n");

        (e2,vars1,idx1,labels)=addTwoLabels(e,e1,true,vars,idx,reduceList);
      then
        (e2,vars1,idx1,labels,true);
    //Substitute real algebraic, state and derivative variables
    case  (e as DAE.CREF(_,DAE.T_REAL(_)),vars,idx,_,_)
      equation

        (e1,true)=substituteExp(e,inVarRepl);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("Add label to real variable " + ExpressionDump.printExpStr(e) +  "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"Add label to real variable " +& ExpressionDump.printExpStr(e) +&  "\n");

        (e2,vars1,idx1,labels)=addTwoLabels(e,e1,true,vars,idx,reduceList);
      then
        (e2,vars1,idx1,labels,true);
    //Do nothing in other cases
    case (e,vars,idx,_,_)
      then (e,vars,idx,{},false);
  end matchcontinue;
end addLabelToExpForSubstitution;

/*
protected function addLabelToExpListForSubstitution
"function that adds labels to expressions for substitution"
  input list<Expression.Exp> inExpLst;
  input SimCodeVar.SimVars inVarLst;
  input tuple<Integer,Integer> inIndex;
  input list<Integer> reduceList;
  input BackendVarTransform.VariableReplacements inVarRepl;
  output list<Expression.Exp> outExpLst;
  output SimCodeVar.SimVars outVarLst;
  output tuple<Integer,Integer> outIndex;
  output list<String> outStringList;
algorithm
  (outExpLst,outVarLst,outIndex,outStringList):=matchcontinue(inExpLst,inVarLst,inIndex,reduceList,inVarRepl)
    local
      Expression.Exp e,e_1,e_2,e1;
      tuple<Integer,Integer> idx1,idx2,idx3;
      list<Expression.Exp> er,er2;
      SimCodeVar.SimVars vars,vars_1,vars_2;
      list<String> labels,labels2,labels3;
      BackendVarTransform.VariableReplacements repl;
    case ({},vars,idx1,reduceList,repl) then ({},vars,idx1,{});
    case ((e1 :: er),vars,idx1,reduceList,repl)
      equation
        (e_1,vars_1,idx2,labels) = addLabelToExpForSubstitution(e1,vars,idx1,reduceList,repl);
        (er2,vars_2,idx3,labels2) = addLabelToExpListForSubstitution(er, vars_1, idx2,reduceList,repl);
        labels3=listAppend(labels,labels2);
      then
        (e_1::er2,vars_2,idx3,labels3);
  end matchcontinue;

end addLabelToExpListForSubstitution;
*/


protected function substituteExp
"function that substitute variables in an expression by their average values"
  input DAE.Exp inExp;
  input BackendVarTransform.VariableReplacements inVarRepl;
  output DAE.Exp outExp;
  output Boolean replPerformed;
algorithm
  (outExp,replPerformed):=matchcontinue(inExp,inVarRepl)
  local
    DAE.Exp e,e1;
    BackendVarTransform.VariableReplacements repl;
    Boolean replPerf;
    case(e,repl)
      equation
        //replaced variable
        (e1,replPerformed)=BackendVarTransform.replaceExp(e,repl,NONE());
      then
        (e1,replPerformed);
  end matchcontinue;
end substituteExp;


protected function multiply
"function that multiplies expression inExp with label named inString"
  input DAE.Exp inExp;
  input String inString;
  output DAE.Exp outExp;

algorithm
  (outExp):=
  matchcontinue (inExp,inString)
      local
        DAE.Exp e,e2;
        String name;
   case  (e,name)
      equation
        e2 = Expression.expMul(DAE.CREF(DAE.CREF_IDENT(name,DAE.T_REAL_DEFAULT,{}),DAE.T_REAL_DEFAULT),e);

        if(Flags.isSet(Flags.REDUCE_DAE)) then
    Debug.trace("generate label  " + ExpressionDump.printExpStr(e2) + " for term " +ExpressionDump.printExpStr(e)+ "\n");
    end if;

        //Debug.fcall(Flags.CPP,print,"generate label  " +& ExpressionDump.printExpStr(e2) +& " for term " +& ExpressionDump.printExpStr(e)+& "\n");

      then
        (e2);
 end matchcontinue;
end multiply;


protected function createLabelVar
"function that creates SimCode.SimVar's named label'i'_1 and label'i'_2"
  input SimCodeVar.SimVars inVariables;
  input Integer inInteger;
  input Integer inInteger2;
  output SimCodeVar.SimVars outVariables;
  output String outString;
algorithm
  (outVariables,outString):=
  matchcontinue (inVariables,inInteger,inInteger2)
    local
     list<SimCodeVar.SimVar> states,derVar,alg,disAlg,intAlg,boolAlg,inVar,outVar,algAlias,intAlias,boolAlias,param,
                          intParam,boolParam,stringAlg,stringParam,stringAlias,extObjVar,const,intConst,boolConst,stringConst,jacobianVar,
              seedVar,realOptConst,realOptFinalConst,sensVar;
     SimCodeVar.SimVar simVar_1,simVar_2;
     list<SimCodeVar.SimVar> param_1,param_2;
     Integer i,p;
     String name, name1, name2, indexStr;
    case (SimCodeVar.SIMVARS(states,derVar,alg,disAlg,intAlg,boolAlg,inVar,outVar,algAlias,intAlias,boolAlias,param,
                           intParam,boolParam,stringAlg,stringParam,stringAlias,extObjVar,const,intConst,boolConst,stringConst,jacobianVar,
               seedVar,realOptConst,realOptFinalConst,sensVar),p,i)

      equation
        indexStr = intString(i);
        name = stringAppend(LABELNAME,indexStr);
        name1 = stringAppend(name,"_1");
        name2 = stringAppend(name,"_2");
        //create simVar for label_1

        simVar_1 = SimCodeVar.SIMVAR(DAE.CREF_IDENT(name1,DAE.T_REAL_DEFAULT,{}),BackendDAE.PARAM(),"","","",p,NONE(),NONE(),SOME(DAE.RCONST(1.0)),NONE(),
                   true,DAE.T_REAL_DEFAULT,false,NONE(),SimCodeVar.NOALIAS(),DAE.emptyElementSource,SimCodeVar.INTERNAL(),NONE(),{},false,false,false,NONE(),NONE());
        param=listReverse(param);
        //add simVar_1 to parameter list
        param_1=simVar_1::param;
        p=p+1;
        //create simVar_2 to parameter list
        simVar_2 = SimCodeVar.SIMVAR(DAE.CREF_IDENT(name2,DAE.T_REAL_DEFAULT,{}),BackendDAE.PARAM(),"","","",p,NONE(),NONE(),SOME(DAE.RCONST(0.0)),NONE(),
                   true,DAE.T_REAL_DEFAULT,false,NONE(),SimCodeVar.NOALIAS(),DAE.emptyElementSource,SimCodeVar.INTERNAL(),NONE(),{},false,false,false,NONE(),NONE());
        //add simVar_2 to parameter list
        param_2=simVar_2::param_1;
        param_2=listReverse(param_2);

      then

        (SimCodeVar.SIMVARS(states,derVar,alg,disAlg,intAlg,boolAlg,inVar,outVar,algAlias,intAlias,boolAlias,param_2,
                           intParam,boolParam,stringAlg,stringParam,stringAlias,extObjVar,const,intConst,boolConst,stringConst,jacobianVar,
               seedVar,realOptConst,realOptFinalConst,sensVar),name);

  end matchcontinue;
end createLabelVar;


protected function makeReduceList
"function that makes an integer list for labels to be reduced"
  input list<Absyn.Exp> expLst;
  input list<Integer> inList;
  output list<Integer> outList "indices of labels that have to be replaced from equations";
algorithm outList := matchcontinue(expLst,inList)
  local
    list<Absyn.Exp> expLstRest;
    Integer v,i;
    list<Integer> lst,lst2,lst3;
    case({},lst)
       then (lst);
    case((Absyn.INTEGER(value=v))::expLstRest,lst)
    equation
         i = v;
         lst2 = listAppend(lst, {i});
         lst3 = makeReduceList(expLstRest,lst2);
      then lst3;
   end matchcontinue;
end makeReduceList;

protected  function StringDelimit2Int
" splits the input string at the delimiter string in list of strings and converts to integer list"
    input String inString;
    input String inDelim;
    output list<Integer> outList;
algorithm
  outList := matchcontinue (inString,inDelim)
    local
      list<String> lst;
      list<Integer> lst2;
      String v,delim;
    case (v,delim)
      equation
        lst=Util.stringSplitAtChar(v,delim);
        lst2=list(stringInt(s) for s in lst);
      then lst2;
    else {};
  end matchcontinue;
end StringDelimit2Int;

public function createBackendLabelVars
"function that creates Backend variables for labels"
  input SimCode.ModelInfo modelInfo;
  output list<BackendDAE.Var> labelList;
algorithm
  labelList := matchcontinue(modelInfo)
  local
    Integer numParams;
    list<String> labels;
    list<BackendDAE.Var> list1;
  case(SimCode.MODELINFO(varInfo=SimCode.VARINFO(numParams=numParams),labels=labels))
    equation
      //NB! index is not correct
      list1=createBackendLabelVars2(labels,numParams);
    then
      list1;
  end matchcontinue;
end createBackendLabelVars;


protected function createBackendLabelVars2
"helper function to create Backend variables for labels"
  input list<String> inLabels;
  input Integer inIndex;
  output list<BackendDAE.Var> outList;
algorithm
  (outList) := matchcontinue(inLabels,inIndex)
  local
    String name,name1,name2;
    list<String> rest;
    BackendDAE.Var var1,var2;
    list<BackendDAE.Var> list1,list2,list3;
    Integer p,p2;
  case({},p) then ({});
  case(name::rest,p)
    equation
      name1 = stringAppend(name,"_1");
      name2 = stringAppend(name,"_2");
      //create Backend variable for label_1


       var1 = BackendDAE.VAR(DAE.CREF_IDENT(name1,DAE.T_REAL_DEFAULT,{}), BackendDAE.PARAM(),DAE.BIDIR(),DAE.NON_PARALLEL(),DAE.T_REAL_DEFAULT,NONE(),SOME(DAE.RCONST(1.0)),{},
                            DAE.emptyElementSource,
                            SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE())),
                            NONE(),DAE.ICONST(p),NONE(),DAE.NON_CONNECTOR(),DAE.NOT_INNER_OUTER(),false);

      p=p+1;


      //create Backend variable for label_2
      var2 = BackendDAE.VAR(DAE.CREF_IDENT(name2,DAE.T_REAL_DEFAULT,{}), BackendDAE.PARAM(),DAE.BIDIR(),DAE.NON_PARALLEL(),DAE.T_REAL_DEFAULT,NONE(),SOME(DAE.RCONST(0.0)),{},
                            DAE.emptyElementSource,
                            SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE())),
                            NONE(),DAE.ICONST(p),NONE(),DAE.NON_CONNECTOR(),DAE.NOT_INNER_OUTER(),false);

      list1={var1,var2};
      p=p+1;
     list2=createBackendLabelVars2(rest,p);
     list3=listAppend(list1,list2);
    then
      (list3);
  end matchcontinue;
end createBackendLabelVars2;

annotation(__OpenModelica_Interface="backend");
end ReduceDAE;
