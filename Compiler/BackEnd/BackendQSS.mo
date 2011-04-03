/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */


encapsulated package BackendQSS
" file:         BackendQSS.mo
  package:     BackendQSS
  description: BackendQSS contains the datatypes used by the backend for QSS solver.
  authors: xfloros, fbergero
"

public import SimCode;
public import BackendDAE;
public import DAE;
public import Absyn;
public import Util;
public import ExpressionDump;
public import Expression;
public import BackendDAEUtil;
public import BackendDump;


protected import BackendVariable;
protected import Debug;
protected import ComponentReference;

public
uniontype DevsStruct "DEVS structure"
  record DEVS_STRUCT  
    array<list<list<Integer>>> outLinks "output connections for each DEVS block";
    array<list<list<Integer>>> outVars "output variables for each DEVS block";  
    array<list<list<Integer>>> inLinks "input connections for each DEVS block";
    array<list<list<Integer>>> inVars "input variables for each DEVS block";   
  end DEVS_STRUCT;
end DevsStruct;

public
uniontype QSSinfo "- equation indices in static blocks and DEVS structure"
  record QSSINFO
    list<list<list<Integer>>> BLTblocks "BLT blocks in static functions";  
    DevsStruct DEVSstructure "DEVS structure of the model";
  end QSSINFO;
end QSSinfo;

public function replaceCondWhens
" author: fbergero
  merge when clauses depending on the same conditions"
  input list<SimCode.SimWhenClause> whenClauses;
  input list<SimCode.HelpVarInfo> helpVars;
input list<BackendDAE.ZeroCrossing> zeroCrossings;
output list<SimCode.SimWhenClause> replacedWhenClauses;
algorithm
replacedWhenClauses := 
match (whenClauses,helpVars,zeroCrossings)
local
list<SimCode.SimWhenClause> rest,r;
SimCode.SimWhenClause clause;
    list<tuple<DAE.Exp, Integer>> cond; // condition, help var index
    list<DAE.ComponentRef> condVars;
    list<BackendDAE.WhenOperator> res;
    Option<BackendDAE.WhenEquation> whEq;
case ({},helpVars,zeroCrossings) then {};
case ((SimCode.SIM_WHEN_CLAUSE(conditions=cond, conditionVars=condVars, reinits=res, whenEq=whEq)::rest),helpVars,zeroCrossings)
equation
r = replaceCondWhens(rest,helpVars,zeroCrossings);
cond = replaceConds(cond,zeroCrossings);
then (SimCode.SIM_WHEN_CLAUSE(condVars,res,whEq,cond)::r);
  end match;
end replaceCondWhens;

protected function replaceConds
  input list<tuple<DAE.Exp, Integer>> conditions; // condition, help var index
input list<BackendDAE.ZeroCrossing> zeroCrossings;
  output list<tuple<DAE.Exp, Integer>> conditionsOut; // condition, help var index
algorithm
conditionsOut :=
match (conditions,zeroCrossings)
local 
  list<tuple<DAE.Exp, Integer>> rest; 
  tuple<DAE.Exp, Integer> cond; 
case ({},_) then {};
case (cond::rest,_)
equation
cond=replaceCond(cond,zeroCrossings);
rest = replaceConds(rest,zeroCrossings);
then (cond::rest);
end match;
end replaceConds;

protected function replaceCond
  input tuple<DAE.Exp, Integer> cond; 
input list<BackendDAE.ZeroCrossing> zeroCrossings;
output tuple<DAE.Exp, Integer> condOut; 
algorithm
condOut :=
matchcontinue (cond,zeroCrossings)
local
Integer i,index;
  DAE.Exp e;
  tuple<DAE.Exp, Integer> result;  
list<DAE.Exp> zce;
list<DAE.Exp> expLst,expLst2;
Boolean tuple_ "tuple" ;
      Boolean builtin "builtin Function call" ;
        DAE.ExpType ty "The type of the return value, if several return values this is undefined";
        DAE.InlineType inlineType;
 
case ((e as (DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst=expLst,tuple_=tuple_,builtin=builtin, ty=ty,inlineType=inlineType)),i),_) 
equation
zce = Util.listMap(zeroCrossings,extractExpresionFromZeroCrossing);
// Remove extra argument to sample since in the zce list there is none
expLst2 = Util.listFirst(Util.listPartition(expLst,2));
e = DAE.CALL(Absyn.IDENT("sample"), expLst2,tuple_,builtin,ty,inlineType);
index = listExpPos(zce,e,0);
result = 
((DAE.CALL(Absyn.IDENT("samplecondition"), {DAE.ICONST(index)}, false, true, DAE.ET_BOOL(), DAE.NO_INLINE()),i));
then result;
case ((e as DAE.RELATION(_,_,_,_,_),i),_) 
equation
zce = Util.listMap(zeroCrossings,extractExpresionFromZeroCrossing);
index = listExpPos(zce,e,0);
then 
((DAE.CALL(Absyn.IDENT("condition"), {DAE.ICONST(index)}, false, true, DAE.ET_BOOL(), DAE.NO_INLINE()),i));
case ((e as DAE.CREF(_,_),i),_)
then
((e,i));
case ((e,_),_)
equation
print("Unhandle match in replaceCond\n");
print(ExpressionDump.dumpExpStr(e,0));
then
((DAE.ICONST(1),1));
  end matchcontinue;
end replaceCond;

protected function listExpPos
input list<DAE.Exp> zce;
input DAE.Exp e;
input Integer i;
output Integer o;
algorithm
o :=
matchcontinue (zce,e,i)
local list<DAE.Exp> rest;
DAE.Exp e1;
case ((e1::rest),_,i)
equation
true = Expression.expEqual(e1,e);
then i;
case ((e1::rest),_,i)
then 
listExpPos(rest,e,i+1);
case ({},_,_) 
equation
print("Fail in listExpPos\n");
then 
fail();
end matchcontinue;
end listExpPos;

protected function extractExpresionFromZeroCrossing
"Takes a ZeroCrossing and returns the associated Expression
author:  FB"
input BackendDAE.ZeroCrossing zc1; 
output DAE.Exp o;
algorithm
o := matchcontinue (zc1)
local 
DAE.Exp o1;
case (BackendDAE.ZERO_CROSSING(relation_= o1)) 
then o1;
end matchcontinue;
end extractExpresionFromZeroCrossing;

public function replaceZC
  input SimCode.SimEqSystem i;
  input list<BackendDAE.ZeroCrossing> zc;
  output SimCode.SimEqSystem o;
algorithm
o := 
matchcontinue (i,zc)
local
DAE.ComponentRef cref;
DAE.Exp exp;
list<DAE.Exp> zce;
    DAE.ElementSource source;
case (SimCode.SES_SIMPLE_ASSIGN(cref=cref,exp=exp,source=source),_)
equation
zce = Util.listMap(zc,extractExpresionFromZeroCrossing);
exp = replaceCrossingLstOnExp(exp,zce,0);
then (SimCode.SES_SIMPLE_ASSIGN(cref,exp,source));
  end matchcontinue;
end replaceZC;

protected function replaceCrossExpHelper1
  "Helper function used to traverse  the expression replacing the zero crossings
  FB"
  input tuple<DAE.Exp, tuple<DAE.Exp,Integer>> inp;
  output tuple<DAE.Exp, tuple<DAE.Exp,Integer>> out;
algorithm
  out := matchcontinue inp
         local 
           DAE.Exp e;
           DAE.Exp zce;
           Integer index;
         case ((e,(zce,index)))
          equation
            true = Expression.expEqual(e , zce);
          then ((DAE.CALL(Absyn.IDENT("condition"), {DAE.ICONST(index)}, false, true, DAE.ET_BOOL(), DAE.NO_INLINE()), (zce,index)));
         case ((e,(zce,index)))
          equation
            then ((e,(zce,index)));
        end matchcontinue;
end replaceCrossExpHelper1;

protected function replaceExpOnEq
  "function replaceExpOnEq takse an Expresion eq and an zero corssing expression and
  traverses the expresion eq replacing zc for CROSSINGCONDITION(inp)
  FB"
  input DAE.Exp eq;
  input DAE.Exp zc;
  input Integer inp;
  output DAE.Exp eqout;
  DAE.Exp temp;
algorithm
  /*
  print("\nReplacing:\n\t");
  print(Exp.printExpStr(zc));
  print("\non:\n\t");
  print(Exp.printExpStr(eq));
  print("\nwith result:\n\t");
  */
  ((temp,_)) := Expression.traverseExp(eq,replaceCrossExpHelper1,(zc,inp));
  /*
  print(Exp.printExpStr(temp));
  print("\n");
  */
  ((eqout,_)) := Expression.traverseExp(eq,replaceCrossExpHelper1,(zc,inp));
end replaceExpOnEq;

protected function replaceCrossingLstOnExp
  "Replace all zero crossing conditions zce1 in equation exp1 for CROSSINGCONDITION(index1)
  FB"
  input DAE.Exp exp1;
  input list<DAE.Exp> zce1;
  input Integer index1;
  output DAE.Exp expOut;
  DAE.Exp e1,e2;
algorithm
  expOut := matchcontinue (exp1,zce1,index1)
            local DAE.Exp exp,e1;
                  list<DAE.Exp> rest,l1,l2;
                  Integer index;
             case (exp,{},_) then exp;
             case (exp,(e1 :: rest),index)
             equation
              exp = replaceExpOnEq(exp,e1,index);
              exp = replaceCrossingLstOnExp(exp,rest,index+1);
             then 
              exp;
  end matchcontinue;
end replaceCrossingLstOnExp;
 
public function generateStructureCodeQSS 
  input BackendDAE.BackendDAE inBackendDAE;
  input array<Integer> equationIndices;
  input array<Integer> variableIndices;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input list<list<Integer>> strongComponents;
  
  output QSSinfo QSSinfo_out;
algorithm
  QSSinfo_out :=
  matchcontinue (inBackendDAE, equationIndices, variableIndices, inIncidenceMatrix, inIncidenceMatrixT, strongComponents)
    local
       BackendDAE.BackendDAE dlow;
       array<Integer> ass1, ass2;
       BackendDAE.IncidenceMatrix m, mt, globalIncidenceMat;
       
       list<Integer> variableIndicesList;
       list<list<Integer>> blt_states,blt_no_states, stateEq_flat, globalIncidenceList, comps;
       list<list<list<Integer>>> stateEq_blt;
       
       Integer nStatic;
       
       // structure variables
       DevsStruct DEVS_structure;
       array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
                         
    case (dlow, ass1, ass2, m, mt, comps)
      equation
        
        (blt_states, blt_no_states) = BackendDAEUtil.generateStatePartition(comps, dlow, ass1, ass2, m, mt);
        
        // STEP 1      
        // EXTRACT THE INDICES OF NEEDED EQUATIONS FOR EACH STATE VARIABLE         
                
        stateEq_flat = splitStateEqSet(comps, dlow, ass1, ass2, m, mt) "Extract equations for each state derivative"; 
        stateEq_blt = mapStateEqInBlocks( stateEq_flat, blt_states, {}) "Map equations back in BLT blocks";
        
        nStatic = listLength(stateEq_blt);     
        
        // STEP 2      
        // GENERALISED INCIDENCE MATRICES
        
        //globalIncidenceList = arrayList(m);
        globalIncidenceMat = m;
        variableIndicesList = arrayList(ass2);
        globalIncidenceMat = makeIncidenceRightHandNeg(globalIncidenceMat, variableIndicesList, 1); 
        
        BackendDump.dumpIncidenceMatrix(globalIncidenceMat);
        
        
        //print("Global Incidence List \n");
        //BackendDump.dumpComponents(globalIncidenceList);
        
        
        DEVS_structure = incidenceMat2DEVSstruct(stateEq_blt, globalIncidenceMat); 
        
        dumpDEVSstructs(DEVS_structure);       
        
        
                
        // PRINT INFO
                
        Debug.fcall("QSS-stuff",print,"---------- State Blocks ----------\n");
        //Util.listMap0(stateEq_blt, printListOfLists);
        //Debug.fcall("QSS-stuff",Util.listMap02, (stateEq_blt, BackendDump.dumpComponentsAdvanced, ass2, dlow));        
        Debug.fcall("QSS-stuff",print,"---------- State Blocks ----------\n");    

        
      then
        QSSINFO(stateEq_blt, DEVS_structure);
  
  end matchcontinue;

end generateStructureCodeQSS;

////////////////////////////////////////////////////////////////////////////////////////////////////
/////  PART - INCIDENCE MATRICES
////////////////////////////////////////////////////////////////////////////////////////////////////

protected function incidenceMat2DEVSstruct
"function: incidenceMat2DEVSstruct
  author: florosx
  Takes as input the generalised incidence matrix and generates the initial overcomplete DEVS structures
"
  input list<list<list<Integer>>> stateEq_blt;
  input BackendDAE.IncidenceMatrix globalIncidenceMat;
  output DevsStruct DEVS_structure;
 
algorithm
  (DEVS_structure):=
  matchcontinue (stateEq_blt, globalIncidenceMat)
    local
      list<list<Integer>> globalIncidenceList;     
      array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
      
    case (stateEq_blt, globalIncidenceMat)
      equation
        DEVS_struct_outLinks = listArray( { {{1,1}, {2,2}}, {{3}, {4}} });
        DEVS_struct_outVars = listArray( { {{1,1}, {2,2}}, {{3}, {4}} }); 
        DEVS_struct_inVars = listArray( { {{1,1}, {2,2}}, {{3}, {4}} });
        DEVS_struct_inLinks = listArray( { {{1,1}, {2,2}}, {{3}, {4}} });

      then
        (DEVS_STRUCT(DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inVars, DEVS_struct_inVars));
    case (_,_)
      equation
        print("- BackendQSS.incidenceMat2DEVSstruct failed\n");
      then
        fail();
  end matchcontinue;
end incidenceMat2DEVSstruct;

protected function makeIncidenceRightHandNeg
"function: makeIncidenceRightHandNeg
  author: florosx
  Takes the incidence matrix and adds negative signs to the variables that are on the right
  hand side in each equation and with a positive sign the variable that is solved there.
"
  input BackendDAE.IncidenceMatrix globalIncidenceMat;
  input list<Integer> ass2_list;
  input Integer curInd;
  
  output BackendDAE.IncidenceMatrix globalIncidenceMatOut;

algorithm
  (globalIncidenceMatOut):=
  matchcontinue (globalIncidenceMat, ass2_list, curInd)
    local
      
      Integer cur_var, curInd, tempInd;
      list<Integer> rest_vars, cur_eq;
      BackendDAE.IncidenceMatrix globalIncidenceMat_temp;       
      
    case(globalIncidenceMat_temp, {}, curInd)
      equation
      then (globalIncidenceMat_temp);
    
    //cur_var is the variable that current equation solves
    case (globalIncidenceMat_temp, cur_var::rest_vars, curInd)
      equation
        // Make everything negative except from the variable that is solved for.
        cur_eq = globalIncidenceMat_temp[curInd];
        tempInd = findElementInList(0, listLength(cur_eq), cur_eq, cur_var);
        cur_eq = makeListNegative(cur_eq, {});
        cur_eq = Util.listReplaceAt(cur_var, tempInd, cur_eq);
        globalIncidenceMat_temp = arrayUpdate(globalIncidenceMat_temp, curInd, cur_eq);
        globalIncidenceMat_temp = makeIncidenceRightHandNeg(globalIncidenceMat_temp, rest_vars, curInd+1);
      then
        (globalIncidenceMat_temp);
     case (_,_,_)
      equation
        print("- BackendQSS.makeIncidenceRightHandNeg failed\n");
      then
        fail();
  end matchcontinue;
end makeIncidenceRightHandNeg;


////////////////////////////////////////////////////////////////////////////////////////////////////
/////  PART - SELECTING EQUATIONS FOR EACH STATE VARIABLE (slight modifications from BackendDAEUtil
////////////////////////////////////////////////////////////////////////////////////////////////////

public function splitStateEqSet
"function: splitStateEqSet
  author: florosx
  Finds for each state derivative the equations that are needed in order to compute it.
  It is based on the traversal done in BackendDAEUtil.generateStatePartition().
"
  input list<list<Integer>> inIntegerLstLst1;
  input BackendDAE.BackendDAE inBackendDAE;
  input array<BackendDAE.Value> inIntegerArray1;
  input array<BackendDAE.Value> inIntegerArray2;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output list<list<Integer>> sortedEquationsIndices;
 
algorithm
  (sortedEquationsIndices):=
  matchcontinue (inIntegerLstLst1,inBackendDAE,inIntegerArray1,inIntegerArray2,inIncidenceMatrix,inIncidenceMatrixT)
    local
      BackendDAE.BackendDAE dae;
      BackendDAE.Value size;
      BackendDAE.Variables v;
      array<BackendDAE.Value> arr;
      array<list<Integer>> arr_1;
      list<list<BackendDAE.Value>> blt_states,blt_no_states;
      array<BackendDAE.Value> ass1,ass2;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      list<list<Integer>> arrList, comps;      
      
    case (comps,(dae as BackendDAE.DAE(orderedVars = v)),ass1,ass2,m,mt)
      equation
        size = arrayLength(ass1) "equation_size(e) => size &" ;
        arr = arrayCreate(size, 0);
        arr_1 = arrayCreate(size, {});
        arr_1 = markStateEquations(dae, arr, arr_1, m, mt, ass1, ass2);
        arrList = arrayList(arr_1); 
        arrList = sortEquationsBLT(arrList,comps,{});        
        //The arrList includes also empty elements for the non-states - remove them
        arrList = removeEmptyElements(arrList,{});       
      then
        (arrList);
    case (_,_,_,_,_,_)
      equation
        print("- BackendQSS.splitStateEqSet failed\n");
      then
        fail();
  end matchcontinue;
end splitStateEqSet;

public function markStateEquations "function: markStateEquations
  This function goes through all equations and marks the ones that
  calculates a state, or is needed in order to calculate a state,
  with a non-zero value in the array passed as argument.
  This is done by traversing the directed graph of nodes where
  a node is an equation/solved variable and following the edges in the
  backward direction.
  inputs: (daeLow: BackendDAE,
             marks: int array,
    incidenceMatrix: IncidenceMatrix,
    incidenceMatrixT: IncidenceMatrixT,
    assignments1: int vector,
    assignments2: int vector)
  outputs: marks: int array"
  input BackendDAE.BackendDAE inBackendDAE1;
  input array<Integer> inIntegerArray2;
  input array<list<Integer>> inEqNumArray3;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix3;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT4;
  input array<Integer> inIntegerArray5;
  input array<Integer> inIntegerArray6;
  output array<list<Integer>> outIntegerArray; //modification
algorithm
  outIntegerArray:=
  matchcontinue (inBackendDAE1,inIntegerArray2,inEqNumArray3,inIncidenceMatrix3,inIncidenceMatrixT4,inIntegerArray5,inIntegerArray6)
    local
      list<BackendDAE.Var> statevar_lst;
      BackendDAE.BackendDAE dae;
      array<BackendDAE.Value> arr_1,arr;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      BackendDAE.Variables v,kn;
      BackendDAE.EquationArray e,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> alg;
      array<list<Integer>> arr_2;
    
    case ((dae as BackendDAE.DAE(orderedVars = v,knownVars = kn,orderedEqs = e,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = alg)),arr_1,arr_2,m,mt,a1,a2)
      equation
        statevar_lst = BackendVariable.getAllStateVarFromVariables(v);
        ((dae,arr_1,arr_2,m,mt,a1,a2)) = Util.listFold(statevar_lst, markStateEquation, (dae,arr_1,arr_2,m,mt,a1,a2));
      then
        arr_2;
    case (_,_,_,_,_,_,_)
      equation
        print("- BackendQSS.markStateEquations failed\n");
      then
        fail();
  end matchcontinue;
end markStateEquations;
     
protected function markStateEquation
"function: markStateEquation
  This function is a helper function to mark_state_equations
  It performs marking for one equation and its transitive closure by
  following edges in backward direction.
  inputs and outputs are tuples so we can use Util.list_fold"
  input BackendDAE.Var inVar;
  input tuple<BackendDAE.BackendDAE, array<Integer>, array<list<Integer>>, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>> inTplBackendDAEIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
  output tuple<BackendDAE.BackendDAE, array<Integer>, array<list<Integer>>, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>> outTplBackendDAEIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
algorithm
  outTplBackendDAEIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray:=
  matchcontinue (inVar,inTplBackendDAEIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray)
    local
      list<BackendDAE.Value> v_indxs,v_indxs_1,eqns;
      array<BackendDAE.Value> arr_1,arr;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      DAE.ComponentRef cr;
      BackendDAE.BackendDAE dae;
      BackendDAE.Variables vars;
      String s,str;
      BackendDAE.Value v_indx,v_indx_1;
      array<list<Integer>> arr_2;
      Integer firstInd;
      
    case (BackendDAE.VAR(varName = cr),((dae as BackendDAE.DAE(orderedVars = vars)),arr_1,arr_2,m,mt,a1,a2))
      equation
        (_,v_indxs) = BackendVariable.getVar(cr, vars);
        firstInd = Util.listFirst(v_indxs); //modification
        v_indxs_1 = Util.listMap1(v_indxs, intSub, 1);
        eqns = Util.listMap1r(v_indxs_1, arrayNth, a1);
        ((arr_1,arr_2,m,mt,a1,a2,_)) = markStateEquation2(eqns, (arr_1,arr_2,m,mt,a1,a2,firstInd));
      then
        ((dae,arr_1,arr_2,m,mt,a1,a2));
    
    case (BackendDAE.VAR(varName = cr),((dae as BackendDAE.DAE(orderedVars = vars)),arr,_,m,mt,a1,a2))
      equation
        failure((_,_) = BackendVariable.getVar(cr, vars));
        print("- BackendQSS.markStateEquation var ");
        s = ComponentReference.printComponentRefStr(cr);
        print(s);
        print("not found\n");
      then
        fail();
    
    case (BackendDAE.VAR(varName = cr),((dae as BackendDAE.DAE(orderedVars = vars)),arr,_,m,mt,a1,a2))
      equation
        (_,{v_indx}) = BackendVariable.getVar(cr, vars);
        v_indx_1 = v_indx - 1;
        failure(_ = a1[v_indx_1 + 1]);
        print("-  BackendQSS.markStateEquation index = ");
        str = intString(v_indx);
        print(str);
        print(", failed\n");
      then
        fail();
  end matchcontinue;
end markStateEquation;

protected function markStateEquation2
"function: markStateEquation2
  Helper function to mark_state_equation
  Does the job by looking at variable indexes and incidencematrices.
  inputs: (eqns: int list,
             marks: (int array  BackendDAE.IncidenceMatrix  BackendDAE.IncidenceMatrixT  int vector  int vector))
  outputs: ((marks: int array  BackendDAE.IncidenceMatrix  IncidenceMatrixT
        int vector  int vector))"
  input list<Integer> inIntegerLst;
  input tuple<array<Integer>, array<list<Integer>>,BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>, Integer> inTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
  output tuple<array<Integer>, array<list<Integer>>, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>, Integer> outTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
algorithm
  outTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray:=
  matchcontinue (inIntegerLst,inTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray)
    local
      array<BackendDAE.Value> marks,marks_1,marks_2,marks_3;
      array<list<BackendDAE.Value>> m,mt,m_1,mt_1;
      array<BackendDAE.Value> a1,a2,a1_1,a2_1;
      BackendDAE.Value eqn_1,eqn,mark_value,len;
      list<BackendDAE.Value> inv_reachable,inv_reachable_1,eqns;
      list<list<BackendDAE.Value>> inv_reachable_2;
      String eqnstr,lens,ms;
      array<list<Integer>> marksEq;
      
      list<Integer> lst;
      array<list<Integer>> marksEq_1,marksEq_2,marksEq_3;
      Integer stateVarIndex;
        
    case ({},(marks,marksEq,m,mt,a1,a2,stateVarIndex)) then ((marks,marksEq,m,mt,a1,a2,stateVarIndex));
    
    case ((eqn :: eqns),(marks,marksEq,m,mt,a1,a2,stateVarIndex))
      equation
        eqn_1 = eqn - 1 "Mark an unmarked node/equation" ;
        0 = marks[eqn_1 + 1];
        marks_1 = arrayUpdate(marks, eqn_1 + 1, 1);
        
        lst = marksEq[stateVarIndex];
        lst = listAppend(lst,{eqn});
        marksEq_1 = arrayUpdate(marksEq,stateVarIndex,lst);
        
        inv_reachable = BackendDAEUtil.invReachableNodes(eqn, m, mt, a1, a2);
        inv_reachable_1 = BackendDAEUtil.removeNegative(inv_reachable);
        inv_reachable_2 = Util.listMap(inv_reachable_1, Util.listCreate);
        ((marks_2,marksEq_2,m,mt,a1,a2,stateVarIndex)) = Util.listFold(inv_reachable_2, markStateEquation2, (marks_1,marksEq_1,m,mt,a1,a2,stateVarIndex));
        ((marks_3,marksEq_3,m_1,mt_1,a1_1,a2_1,stateVarIndex)) = markStateEquation2(eqns, (marks_2,marksEq_2,m,mt,a1,a2,stateVarIndex));
      then
        ((marks_3,marksEq_3,m_1,mt_1,a1_1,a2_1,stateVarIndex));
    
    case ((eqn :: eqns),(marks,marksEq,m,mt,a1,a2,stateVarIndex))
      equation
        eqn_1 = eqn - 1 "Node already marked." ;
        mark_value = marks[eqn_1 + 1];
        (mark_value <> 0) = true;
        ((marks_1,marksEq_1,m_1,mt_1,a1_1,a2_1,stateVarIndex)) = markStateEquation2(eqns, (marks,marksEq,m,mt,a1,a2,stateVarIndex));
      then
        ((marks_1,marksEq_1,m_1,mt_1,a1_1,a2_1,stateVarIndex));
    
    case ((eqn :: _),(marks,marksEq,m,mt,a1,a2,stateVarIndex))
      equation
        print("- BackendQSS.markStateEquation2 failed, eqn: ");
        eqnstr = intString(eqn);
        print(eqnstr);
        print("array length = ");
        len = arrayLength(marks);
        lens = intString(len);
        print(lens);
        print("\n");
        eqn_1 = eqn - 1;
        mark_value = marks[eqn_1 + 1];
        ms = intString(mark_value);
        print("mark_value: ");
        print(ms);
        print("\n");
      then
        fail();
  end matchcontinue;
end markStateEquation2;

function sortEquationsBLT 
"function: sortEquationsBLT
  author: florosx
  Sorts equations according to their order in the BLT blocks
"
  input list<list<Integer>> inList;
  input list<list<Integer>> inComps;
  input list<list<Integer>> inListAcc;  
  output list<list<Integer>> outList; 
algorithm
  (outList) :=
  matchcontinue (inList,inComps,inListAcc)
    local
      Integer[:] ass1,ass2;
      list<list<Integer>> localAccList;
      list<list<Integer>> restList;
      list<list<Integer>> comps;  
      list<Integer> comps2,elem,firstList;
    case ({},_,localAccList) then localAccList;
    case (firstList :: restList,comps,localAccList)      
      equation 
        comps2 = Util.listFlatten(comps);
        elem = Util.listIntersectionOnTrue(comps2,firstList,intEq);
        localAccList = listAppend(localAccList,{elem});
        localAccList = sortEquationsBLT(restList,comps,localAccList);  
      then localAccList;
    case (_,_,_)
      equation
        print("- BackendQSS.sortEquationsBLT failed\n");
      then
        fail(); 
  end matchcontinue; 
end sortEquationsBLT;

public function mapStateEqInBlocks
"function: mapStateEqInBlocks
  author: florosx
  Maps Equations into BLT blocks
"   
   input list<list<Integer>> inIntegerLstLst1, inIntegerLstLst2;
   input list<list<list<Integer>>> inIntegerLstLstLst1;
   
   output list<list<list<Integer>>> state_blocks_ind;
   
algorithm 
  state_blocks_ind :=
  matchcontinue (inIntegerLstLst1, inIntegerLstLst2, inIntegerLstLstLst1)    
    local
      list<list<Integer>> sorted_indices, blt_states;
      list<list<list<Integer>>> state_blocks, current_state_blocks;
      
      list<Integer> cur_state;
      list<list<Integer>> rest_states, cur_state_blocks;
      
    case ({}, blt_states, state_blocks)
      equation
      then(state_blocks);
    case (cur_state :: rest_states, blt_states, state_blocks)
      equation                     
        cur_state_blocks = mapStateEqInBlocks2(cur_state, blt_states, {});       
        current_state_blocks = listAppend(state_blocks, {cur_state_blocks});  
        state_blocks = mapStateEqInBlocks(rest_states, blt_states, current_state_blocks);
     then
       (state_blocks);
    case (_,_,_)
      equation
        print("- BackendQSS.mapStateEqInBlocks failed\n");
      then
        fail();       
  end matchcontinue;
end mapStateEqInBlocks;

public function mapStateEqInBlocks2
"function: mapStateEqInBlocks2
  author: florosx
  Helper function for mapStateEqInBlocks2
"    
   input list<Integer> inIntegerLst1;
   input list<list<Integer>> inIntegerLstLst1, inIntegerLstLst2;
   
   output list<list<Integer>> cur_state_blocks;
   
algorithm 
  cur_state_blocks :=
  matchcontinue (inIntegerLst1, inIntegerLstLst1, inIntegerLstLst2)    
    local
      list<list<Integer>> sorted_indices, blt_states;
      
      list<Integer> state_equations, cur_block, remain_state_equations, cur_state_blocks, rest_eq;
      list<list<Integer>> rest_blocks, state_blocks, current_state_blocks;     
      
      Integer cur_eq;  
      
   case (_ , {} , state_blocks)
      equation
      then(state_blocks);
   case ({} , _ , state_blocks)
      equation
      then(state_blocks);
                     
    case (cur_eq :: rest_eq , cur_block :: rest_blocks , state_blocks)
      equation
        true = listMember(cur_eq, cur_block);
        current_state_blocks = listAppend(state_blocks, {cur_block});
        remain_state_equations = removeRedundantEquations(rest_eq, cur_block, {});
        state_blocks = mapStateEqInBlocks2(remain_state_equations, rest_blocks, current_state_blocks);
      then
        (state_blocks);
    case (cur_eq :: rest_eq , cur_block :: rest_blocks , state_blocks)
      equation
        false = listMember(cur_eq, cur_block);
        state_equations = cons(cur_eq, rest_eq);
        state_blocks = mapStateEqInBlocks2(state_equations, rest_blocks, state_blocks);
      then
        (state_blocks);
    case (_,_,_)
      equation
        print("- BackendQSS.mapStateEqInBlocks2 failed\n");
      then
        fail();   
   end matchcontinue;
end mapStateEqInBlocks2;

public function removeRedundantEquations
"function: removeRedundantEquations
  author: florosx
"    
   input list<Integer> inIntegerLst1, inIntegerLst2, inIntegerLst3;  
   output list<Integer> remaining_equations;
   
algorithm 
  remaining_equations :=
  matchcontinue (inIntegerLst1, inIntegerLst2, inIntegerLst3)    
    local  
      list<Integer> rest_eq, cur_block, non_redundant_eq;
      Integer cur_eq;
   case ({},_,non_redundant_eq)
      equation
      then(non_redundant_eq);        
    case (cur_eq :: rest_eq , cur_block, non_redundant_eq)
      equation
        true = listMember(cur_eq, cur_block);
        non_redundant_eq = removeRedundantEquations(rest_eq, cur_block, non_redundant_eq); 
      then
         (non_redundant_eq); 
    case (cur_eq :: rest_eq , cur_block, non_redundant_eq)
      equation
        false = listMember(cur_eq, cur_block);
        non_redundant_eq = listAppend(non_redundant_eq, {cur_eq});
        non_redundant_eq = removeRedundantEquations(rest_eq, cur_block, non_redundant_eq); 
      then
         (non_redundant_eq); 
   case (_,_,_)
      equation
        print("- BackendQSS.removeRedundantEquations failed\n");
      then
        fail();   
     end matchcontinue;
end removeRedundantEquations;





////////////////////////////////////////////////////////////////////////////////////////////////////
/////  PART - UTIL FUNCTIONS
////////////////////////////////////////////////////////////////////////////////////////////////////

public function removeEmptyElements
"function: removeEmptyElements
  author: florosx
  Removes empty elements from a list
"
   
   input list<list<Integer>> arrList;
   input list<list<Integer>> arrList1;
   
   output list<list<Integer>> reducedList;
   
algorithm 
  reducedList:=
  matchcontinue (arrList, arrList1)   
    local
      list<list<Integer>> rest_list, cur_list;
      list<Integer> head;
    
    case ({}, cur_list)
      equation
        //END OF RECURSION
     then
       (cur_list);
    case (head::rest_list, cur_list)
      equation
        true = Util.isListNotEmpty(head);
        cur_list = listAppend(cur_list, {head});
        reducedList = removeEmptyElements(rest_list, cur_list);
     then
       (reducedList);
    case (head::rest_list, cur_list)      
      equation
        false = Util.isListNotEmpty(head);
        reducedList = removeEmptyElements(rest_list, cur_list);
     then
       (reducedList);
   end matchcontinue;
end removeEmptyElements;

public function printList
"function: printList
  author: florosx
  Prints the elements of a list of integers
"   
   input list<Integer> arrList;  
algorithm 
  _:=
  matchcontinue (arrList)     
    local 
      list<Integer> restList;
      Integer elem;
    case ({})
      equation
      then();
    case (elem::restList)
      equation 
        print(" ");      
        print(intString(elem));
        print(",");
        printList(restList);
     then
       ();      
       end matchcontinue;
end printList;

public function printListOfLists
"function: printListOfLists
  author: florosx
  Prints the elements of a list of lists of integers
"     
   input list<list<Integer>> arrList;
   
algorithm 
  _:=
  matchcontinue (arrList)
    local
       list<list<Integer>> restList;
       list<Integer> elem;
    case ({})
      equation
          print("\n");
      then();
    case (elem::restList)
      equation    
        printList(elem);
        print("--");
        printListOfLists(restList);
     then
       ();      
       end matchcontinue;
end printListOfLists;


public function dumpDEVSstructs 
"function: dumpDEVSstructs
  author: florosx
  Dumps all 4 DEVS structures: outLinks, outNames, inLinks, inNames
"
  input DevsStruct Devs_structure;

algorithm
  _ := matchcontinue (Devs_structure)
    local
      array<list<list<Integer>>> outLinks1, outVars1, inLinks1, inVars1;
    case (DEVS_STRUCT(outLinks=outLinks1, outVars=outVars1, inLinks=inLinks1, inVars=inVars1))
      equation
        print("---------- DEVS STRUCTURE ----------\n");
        print("DEVS structure Incidence Matrices (row == DEVS block)\n");
        dumpDEVSstruct(outLinks1, "OUT LINKS\n");
        dumpDEVSstruct(outVars1, "OUT VARNAMES\n");
        dumpDEVSstruct(inLinks1, "IN LINKS\n");
        dumpDEVSstruct(inVars1, "IN VARNAMES\n");  
        print("---------- DEVS STRUCTURE ----------\n");      
    then ();
  end matchcontinue;
end dumpDEVSstructs;

public function dumpDEVSstruct 
"function: Based on DAELow.dumpIncidenceMatrix
  author: florosx
  Dumps the incidence matrix for a DEVS structure
"
  input array<list<list<Integer>>> m;
  input String text;
  list<list<list<Integer>>> m_1;
algorithm
  print("====================================\n");
  print(text);
  m_1 := arrayList(m);
  dumpDEVSstruct2(m_1,1);
end dumpDEVSstruct;

protected function dumpDEVSstruct2 
"function: dumpMyDEVSstruct2
  author: florosx
  Helper function for dympMyDEVSstruct
"
  input list<list<list<Integer>>> inList;
  input Integer rowIndex;
algorithm
  _ := matchcontinue (inList,rowIndex)
    local
      list<list<Integer>> row;
      list<list<list<Integer>>> rows;
    case ({},_) then ();
    case ((row :: rows),rowIndex)
      equation
        print("Block #");
        print(intString(rowIndex));print(":");
        dumpIncidenceRow(row);
        dumpDEVSstruct2(rows,rowIndex+1);
      then
        ();
  end matchcontinue;
end dumpDEVSstruct2;

protected function dumpIncidenceRow 
"function: dumpIncidenceRow
  author: florosx
  Helper function for dympMyDEVSstruct
"
  input list<list<Integer>> inList;
algorithm
  _ := matchcontinue (inList)
    local
      String s;
      list<Integer> x;
      list<list<Integer>> xs;
    case ({})
      equation
        print("\n");
      then
        ();
    case ((x :: xs))
      equation
        printList(x);
        print("--");
        dumpIncidenceRow(xs);
      then
        ();
  end matchcontinue;
end dumpIncidenceRow;

public function makeListNegative 
"function: dump
  This function dumps the DAELow representaton to stdout."
  input list<Integer> listIn1;
  input list<Integer> listIn2;
  output list<Integer> listOut;
algorithm
  listOut:=
  matchcontinue (listIn1, listIn2)
    local
      list<Integer> curList, rest_list;
      Integer cur_el;
    case ({}, curList)
      equation     
      then 
        (curList);           
    case (cur_el::rest_list, curList)
      equation
        true = cur_el > 0; 
        cur_el = -cur_el;
        curList = listAppend(curList, {cur_el});
        curList = makeListNegative(rest_list, curList);        
      then
        (curList);
    case (cur_el::rest_list, curList)
      equation
        true = cur_el < 0; 
        curList = listAppend(curList, {cur_el});
        curList = makeListNegative(rest_list, curList);        
      then
        (curList);
   end matchcontinue;
end makeListNegative;

public function findElementInList
"function: 
  author: XF
"
  input Integer loopIndex1;
  input Integer nElements;
  input list<Integer> inList1;
  input Integer element1;
  
  output Integer indexFound; 
  
algorithm
  (indexFound):=
  matchcontinue (loopIndex1, nElements, inList1, element1)
    local
      list<Integer> inList_temp, rest_list;
      Integer cur_elem, temp, element, loopIndex;
      
    case(loopIndex, nElements, cur_elem::rest_list , element)
      equation
        true = cur_elem == element;
        // END OF RECURSION
      then (loopIndex);
    case(loopIndex, 0, {} , element)
      equation
        // IF ELEMENT NOT FOUND RETURN -1
      then (-1);
        
     case(loopIndex, nElements, cur_elem::rest_list , element)
      equation
        temp = findElementInList(loopIndex+1, nElements-1, rest_list, element);
      then
         (temp);
  end matchcontinue;
end findElementInList;

////////////////////////////////////////////////////////////////////////////////////////////////////
/////  END OF PACKAGE
////////////////////////////////////////////////////////////////////////////////////////////////////
end BackendQSS;
