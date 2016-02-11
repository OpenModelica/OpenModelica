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

encapsulated package Matching
" file:        Matching.mo
  package:     Matching
  description: Matching contains functions for matching algorithms"



public import BackendDAE;
public import BackendDAEFunc;
public import DAE;

protected import Array;
protected import BackendDAEEXT;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import ClockIndexes;
protected import Config;
protected import DAEUtil;
protected import Debug;
protected import DumpGraphML;
protected import Error;
protected import Flags;
protected import IndexReduction;
protected import List;
protected import Util;
protected import System;

// =============================================================================
// just a matching algorithm
// - PerfectMatching
// - RegularMatching
//
// =============================================================================

public function PerfectMatching "
  This function fails if there is no perfect matching for the given system."
  input BackendDAE.IncidenceMatrix m;
  output array<Integer> ass1 "eqn := ass1[var]";
  output array<Integer> ass2 "var := ass2[eqn]";
protected
  Boolean perfectMatching;
  Integer N = arrayLength(m);
algorithm
  (ass1, ass2, true) := RegularMatching(m, N, N);
end PerfectMatching;

public function RegularMatching "
  This function returns at least a partial matching for singular systems.
  Unmatched nodes are represented by -1."
  input BackendDAE.IncidenceMatrix m;
  input Integer nVars;
  input Integer nEqns;
  output array<Integer> ass1 "eqn := ass1[var]";
  output array<Integer> ass2 "var := ass2[eqn]";
  output Boolean outPerfectMatching=true;
protected
  Integer i, j;
  array<Boolean> eMark, vMark;
algorithm
  ass2 := arrayCreate(nEqns, -1);
  ass1 := arrayCreate(nVars, -1);
  vMark := arrayCreate(nVars, false);
  eMark := arrayCreate(nEqns, false);

  i := 1;
  while i<=nEqns and outPerfectMatching loop
    j := ass2[i];
    if (j>0 and ass1[j] == i) then
      outPerfectMatching :=true;
    else
      Array.setRange(1, nVars, vMark, false);
      Array.setRange(1, nEqns, eMark, false);
      outPerfectMatching := BBPathFound(i, m, eMark, vMark, ass1, ass2);
    end if;
    i := i+1;
  end while;
end RegularMatching;

public function BBMatching
  input BackendDAE.EqSystem inSys;
  input BackendDAE.Shared inShared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem outSys = inSys;
  output BackendDAE.Shared outShared = inShared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg = inArg;
protected
  Integer i;
  Boolean success = true;
  BackendDAE.IncidenceMatrix m;
  Integer nVars, nEqns, j;
  array<Integer> ass1, ass2;
  array<Boolean> eMark, vMark;
  BackendDAE.EquationArray eqns;
  BackendDAE.Variables vars;
  list<Integer> mEqns;
algorithm
  //BackendDAE.EQSYSTEM(m=SOME(m), matching=BackendDAE.MATCHING(ass1=ass1, ass2=ass2)) := outSys;
  SOME(m) := outSys.m;
  nEqns := BackendDAEUtil.systemSize(outSys);
  nVars := BackendVariable.daenumVariables(outSys);
  // Be carefull, since matching may have been generated with not distinguishing between
  // state and their derivative, which leads to wrong traversing of bibartite graph!!!!
  //(ass1, ass2) := getAssignment(clearMatching, nVars, nEqns, inSys);
  //if clearMatching then
  ass2 := arrayCreate(nEqns, -1);
  ass1 := arrayCreate(nVars, -1);
  //BBCheapMatching(nEqns, m, ass1, ass2);
  //end if;
  vMark := arrayCreate(nVars, false);
  eMark := arrayCreate(nEqns, false);
  i := 1;
  while i<=nEqns and success loop
    j := ass2[i];
    if ((j>0) and ass1[j] == i) then
      success :=true;
    else
      Array.setRange(1, nVars, vMark, false);
      Array.setRange(1, nEqns, eMark, false);
      success := BBPathFound(i, m, eMark, vMark, ass1, ass2);
      if not success then
        mEqns := {};
        for j in 1:nEqns loop
          if eMark[j] then
            mEqns:=j::mEqns;
          end if;
        end for;
        (_, i, outSys, outShared, ass1, ass2, outArg) := sssHandler({mEqns}, i, outSys, outShared, ass1, ass2, outArg);
        SOME(m) := outSys.m;
        //nEqns := BackendDAEUtil.systemSize(outSys);
        //nVars := BackendVariable.daenumVariables(outSys);
        //ass1 := assignmentsArrayExpand(ass1, nVars, arrayLength(ass1), -1);
        //ass2 := assignmentsArrayExpand(ass2, nEqns, arrayLength(ass2), -1);
        //vMark := assignmentsArrayBooleanExpand(vMark, nVars, arrayLength(vMark), false);
        //eMark := assignmentsArrayBooleanExpand(eMark, nEqns, arrayLength(eMark), false);
        success := true;
        i := i-1;
      end if;
    end if;
    i := i+1;
  end while;
  if success then
    outSys := BackendDAEUtil.setEqSystMatching(outSys, BackendDAE.MATCHING(ass1, ass2, {}));
  else
    print("\nSingular System!!!\n");
  end if;
end BBMatching;

protected function BBPathFound
  input Integer i;
  input BackendDAE.IncidenceMatrix m;
  input array<Boolean> eMark;
  input array<Boolean> vMark;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output Boolean success=false;
algorithm
  arrayUpdate(eMark, i, true);

  for j in m[i] loop
    // negative entries in adjacence matrix belong to states!!!
    if (j>0 and ass1[j] <= 0) then
      success := true;
      arrayUpdate(ass1, j, i);
      arrayUpdate(ass2, i, j);
      return;
    end if;
  end for;

  for j in m[i] loop
    // negative entries in adjacence matrix belong to states!!!
    if (j>0 and not vMark[j]) then
      arrayUpdate(vMark, j, true);
      success := BBPathFound(ass1[j], m, eMark, vMark, ass1, ass2);
      if success then
        arrayUpdate(ass1, j, i);
        arrayUpdate(ass2, i, j);
        return;
      end if;
    end if;
  end for;
end BBPathFound;

protected function BBCheapMatching
  input Integer nEqns;
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
protected
  Integer i, j;
  Boolean success=false;
  list<Integer> vars;
algorithm
  for i in 1:nEqns loop
    vars := m[i];
    while not success and (listLength(vars) > 0) loop
      j::vars := vars;
      // negative entries in adjacence matrix belong to states!!!
      if (j>0 and ass1[j] <= 0) then
        success := true;
        arrayUpdate(ass1, j, i);
        arrayUpdate(ass2, i, j);
      end if;
    end while;
  end for;
end BBCheapMatching;

public function invertMatching "author: lochel
  ass1 <-> ass2"
  input array<Integer> inAss;
  output array<Integer> outAss;
protected
  Integer N = arrayLength(inAss);
  Integer j;
algorithm
  outAss := arrayCreate(N, -1);
  for i in 1:N loop
    j := inAss[i];
    if j > 0 then
      outAss[inAss[i]] := i;
    end if;
  end for;
end invertMatching;

// =============================================================================
// Matching Algorithms
//
// =============================================================================

public function DFSLH
"depth first search with look ahead feature. basically the same like MC21A."
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2,emark,vmark;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;

    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        vmark = arrayCreate(nvars,-1);
        emark = arrayCreate(neqns,-1);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        _ = cheapmatchingalgorithm(nvars,neqns,m,mt,vec1,vec2,false);
        (vec1,vec2,syst,shared,arg) = DFSLH2(isyst,ishared,nvars,neqns,1,emark,vmark,vec1,vec2,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec1,vec2,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.DFSLH failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end DFSLH;

protected function DFSLH2
"author: PA
  This is the outer loop of the matching algorithm
  The find_path algorithm is called for each equation/variable.
  inputs:  (BackendDAE,IncidenceMatrix, IncidenceMatrixT
             ,int /* number of vars */
             ,int /* number of eqns */
             ,int /* current var */
             ,Assignments  /* assignments, array of eqn indices */
             ,Assignments /* assignments, array of var indices */
             ,MatchingOptions) /* options for matching alg. */
  outputs: (Assignments, /* assignments, array of equation indices */
              Assignments, /* assignments, list of variable indices */
              BackendDAE, BackendDAE.IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer nf;
  input Integer i;
  input array<Integer> emark;
  input array<Integer> vmark;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input BackendDAE.MatchingOptions match_opts;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAssignments1,outAssignments2,osyst,oshared,outArg):=
  matchcontinue (isyst,ishared,nv,nf,i,emark,vmark,ass1,ass2,match_opts,sssHandler,inArg)
    local
      array<Integer> ass1_1,ass2_1,ass1_2,ass2_2,ass1_3,ass2_3,emark1,vmark1;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      Integer i_1,nv_1,nf_1;
      BackendDAE.EquationArray eqns;
      list<Integer> eqn_lst,var_lst,meqns;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGe(i,nv);
        (ass1_1,ass2_1) = pathFound(m, mt, i, i,emark, vmark, ass1, ass2) "eMark(i)=vMark(i)=false; eMark(i)=vMark(i)=false exit loop";
      then
        (ass1_1,ass2_1,syst,ishared,inArg);

    case (syst as BackendDAE.EQSYSTEM(m=SOME(_),mT=SOME(_)),_,_,_,_,_,_,_,_,_,_,_)
      equation
        i_1 = i + 1;
        true = intGt(ass2[i],0);
        (ass1_2,ass2_2,syst,shared,arg) = DFSLH2(syst, ishared, nv, nf, i_1, emark, vmark, ass1, ass2, match_opts, sssHandler, inArg);
      then
        (ass1_2,ass2_2,syst,shared,arg);

    case (syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_,_,_,_)
      equation
        i_1 = i + 1;
        (ass1_1,ass2_1) = pathFound(m, mt, i, i,emark, vmark, ass1, ass2) "eMark(i)=vMark(i)=false";
        (ass1_2,ass2_2,syst,shared,arg) = DFSLH2(syst, ishared, nv, nf, i_1, emark, vmark, ass1_1, ass2_1, match_opts, sssHandler, inArg);
      then
        (ass1_2,ass2_2,syst,shared,arg);

    case (_,_,_,_,_,_,_,_,_,(BackendDAE.INDEX_REDUCTION(),_),_,_)
      equation
        meqns = getMarked(nf,i,emark,{});
        (_,i_1,syst,shared,ass1_1,ass2_1,arg) = sssHandler({meqns},i,isyst,ishared,ass1,ass2,inArg)
        "path_found failed, Try index reduction using dummy derivatives.
         When a constraint exist between states and index reduction is needed
         the dummy derivative will select one of the states as a dummy state
         (and the derivative of that state as a dummy derivative).
         For instance, u1=u2 is a constraint between states. Choose u1 as dummy state
         and der(u1) as dummy derivative, named der_u1. The differentiated function
         then becomes: der_u1 = der(u2).
         In the dummy derivative method this equation is added and the original equation
         u1=u2 is kept. This is not the case for the original pantilides algorithm, where
         the original equation is removed from the system.";
        eqns = BackendEquation.getEqnsFromEqSystem(syst);
        nf_1 = BackendDAEUtil.equationSize(eqns) "and try again, restarting. This could be optimized later. It should not
                                   be necessary to restart the matching, according to Bernard Bachmann. Instead one
                                   could continue the matching as usual. This was tested (2004-11-22) and it does not
                                   work to continue without restarting.
                                   For instance the Influenca model \"../testsuite/mofiles/Influenca.mo\" does not work if
                                   not restarting.
                                   2004-12-29 PA. This was a bug, assignment lists needed to be expanded with the size
                                   of the system in order to work. SO: Matching is not needed to be restarted from
                                   scratch.";
        nv_1 = BackendVariable.varsSize(BackendVariable.daeVars(syst));
        ass1_2 = assignmentsArrayExpand(ass1_1, nv_1,arrayLength(ass1_1),-1);
        ass2_2 = assignmentsArrayExpand(ass2_1, nf_1,arrayLength(ass2_1),-1);
        vmark1 = assignmentsArrayExpand(vmark, nv_1,arrayLength(vmark),-1);
        emark1 = assignmentsArrayExpand(emark, nf_1,arrayLength(emark),-1);
        (ass1_3,ass2_3,syst,shared,arg1) = DFSLH2(syst,shared,nv_1,nf_1,i_1,emark1, vmark1,ass1_2,ass2_2,match_opts,sssHandler,arg);
      then
        (ass1_3,ass2_3,syst,shared,arg1);

    case (_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        eqn_lst = getMarked(nf,i,emark,{});
        singularSystemError({eqn_lst},i,isyst,ishared,ass1,ass2,inArg);
      then
        fail();
  end matchcontinue;
end DFSLH2;

protected function pathFound "author: PA
  This function is part of the matching algorithm.
  It tries to find a matching for the equation index given as
  third argument, i.
  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int /* equation */,
               Assignments, Assignments)
  outputs: (Assignments, Assignments)"
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer i;
  input Integer imark;
  input array<Integer> emark;
  input array<Integer> vmark;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (m,mt,i,imark,emark,vmark,ass1,ass2)
    local
      array<Integer> ass1_1,ass2_1;
    case (_,_,_,_,_,_,_,_)
      equation
        arrayUpdate(emark,i,imark) "Side effect";
        (ass1_1,ass2_1) = assignOneInEqn(m, mt, i, ass1, ass2);
      then
        (ass1_1,ass2_1);
    case (_,_,_,_,_,_,_,_)
      equation
        (ass1_1,ass2_1) = forallUnmarkedVarsInEqn(m, mt, i, imark, emark, vmark, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end pathFound;

protected function assignOneInEqn "author: PA
  Helper function to pathFound."
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer i;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2;
protected
  list<Integer> vars;
algorithm
  vars := BackendDAEUtil.varsInEqn(m, i);
  (outAssignments1,outAssignments2):= assignFirstUnassigned(i, vars, ass1, ass2);
end assignOneInEqn;

protected function assignFirstUnassigned
"author: PA
  This function assigns the first unassign variable to the equation
  given as first argument. It is part of the matching algorithm.
  inputs:  (int /* equation */,
            int list /* variables */,
            BackendDAE.Assignments /* ass1 */,
            BackendDAE.Assignments /* ass2 */)
  outputs: (Assignments,  /* ass1 */
            Assignments)  /* ass2 */"
  input Integer i;
  input list<Integer> inIntegerLst2;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (i,inIntegerLst2,ass1,ass2)
    local
      array<Integer> ass1_1,ass2_1;
      Integer v;
      list<Integer> vs;
    case (_,(v :: _),_,_)
      equation
        false = intGt(ass1[v],0);
        ass1_1 = arrayUpdate(ass1,v,i);
        ass2_1 = arrayUpdate(ass2,i,v);
      then
        (ass1_1,ass2_1);
    case (_,(_ :: vs),_,_)
      equation
        (ass1_1,ass2_1) = assignFirstUnassigned(i, vs, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end assignFirstUnassigned;

protected function forallUnmarkedVarsInEqn
"author: PA
  This function is part of the matching algorithm.
  It loops over all umarked variables in an equation.
  inputs:  (IncidenceMatrix,
            IncidenceMatrixT,
            int,
            BackendDAE.Assignments /* ass1 */,
            BackendDAE.Assignments /* ass2 */)
  outputs: (Assignments, Assignments)"
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer i;
  input Integer imark;
  input array<Integer> emark;
  input array<Integer> vmark;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2;
protected
  list<Integer> vars,vars_1;
algorithm
  vars := BackendDAEUtil.varsInEqn(m, i);
  vars_1 := List.filter1(vars, isNotVMarked, (imark, vmark));
 (outAssignments1,outAssignments2) := forallUnmarkedVarsInEqnBody(m, mt, i, imark, emark, vmark, vars_1, ass1, ass2);
end forallUnmarkedVarsInEqn;

protected function isNotVMarked
"author: PA
  This function succeds for variables that are not marked."
  input Integer i;
  input tuple<Integer,array<Integer>> inTpl;
protected
  Integer imark;
  array<Integer> vmark;
algorithm
  (imark,vmark) := inTpl;
  false := intEq(imark,vmark[i]);
end isNotVMarked;

protected function forallUnmarkedVarsInEqnBody
"author: PA
  This function is part of the matching algorithm.
  It is the body of the loop over all unmarked variables.
  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT,
            int,
            int list /* var list */
            Assignments
            Assignments)
  outputs: (Assignments, Assignments)"
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer i;
  input Integer imark;
  input array<Integer> emark;
  input array<Integer> vmark;
  input list<Integer> inIntegerLst4;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (m,mt,i,imark,emark,vmark,inIntegerLst4,ass1,ass2)
    local
      Integer assarg,v;
      array<Integer> ass1_1,ass2_1,ass1_2,ass2_2;
      list<Integer> vars,vs;
    case (_,_,_,_,_,_,((v :: _)),_,_)
      equation
        arrayUpdate(vmark,v,imark);
        assarg = ass1[v];
        (ass1_1,ass2_1) = pathFound(m, mt, assarg, imark, emark, vmark, ass1, ass2);
        ass1_2 = arrayUpdate(ass1_1,v,i);
        ass2_2 = arrayUpdate(ass2_1,i,v);
      then
        (ass1_2,ass2_2);
    case (_,_,_,_,_,_,((_ :: vs)),_,_)
      equation
        (ass1_1,ass2_1) = forallUnmarkedVarsInEqnBody(m, mt, i, imark, emark, vmark, vs, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end forallUnmarkedVarsInEqnBody;


public function BFSB
"        complexity O(n*tau)
 author: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> rowmarks,parentcolum;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;

    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        rowmarks = arrayCreate(nvars,-1);
        parentcolum = arrayCreate(nvars,-1);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        _ = cheapmatchingalgorithm(nvars,neqns,m,mt,vec1,vec2,false);
        (vec1,vec2,syst,shared,arg) = BFSB1(1,1,nvars,neqns,m,mt,rowmarks,parentcolum,vec1,vec2,isyst,ishared,inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);

    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);

    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.BFSB failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end BFSB;

protected function BFSB1
"function helper for BFSB, traverses all colums and perform a BFSB phase on each
 author: Frenkel TUD 2012-03"
  input Integer i;
  input Integer rowmark;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> parentcolum;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  matchcontinue (i,rowmark,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2,isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      list<Integer> visitedcolums;
      BackendDAE.IncidenceMatrix m1,mt1;
      Integer nv_1,ne_1,i_1;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2,rowmarks1,parentcolum1;

    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true=intGt(i,ne);
      then
        (ass1,ass2,isyst,ishared,inArg);

    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // not assigned
        false = intGt(ass1[i],0);
        // search augmenting paths
        visitedcolums = BFSBphase({i},rowmark,i,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2,{},{});
        // if visitedcolums is not zero matching fails -> try index reduction and matching aggain
        (_,i_1,syst as BackendDAE.EQSYSTEM(m=SOME(m1),mT=SOME(mt1)),shared,nv_1,ne_1,ass1_1,ass2_1,arg) = reduceIndexifNecessary(visitedcolums,i,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        rowmarks1 = assignmentsArrayExpand(rowmarks,nv_1,arrayLength(rowmarks),-1);
        parentcolum1 = assignmentsArrayExpand(parentcolum,nv_1,arrayLength(parentcolum),-1);
        (ass1_2,ass2_2,syst,shared,arg) = BFSB1(i_1,rowmark+1,nv_1,ne_1,m1,mt1,rowmarks1,parentcolum1,ass1_1,ass2_1,syst,shared,inMatchingOptions,sssHandler,arg);
      then
        (ass1_2,ass2_2,syst,shared,arg);

    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(ass1[i],0);
        (ass1_1,ass2_1,syst,shared,arg) = BFSB1(i+1,rowmark,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2,isyst,ishared,inMatchingOptions,sssHandler,inArg);
      then
        (ass1_1,ass2_1,syst,shared,arg);

    else
      equation
        Error.addInternalError("function BFSB1 failed in equation " + intString(i), sourceInfo());
      then
        fail();

  end matchcontinue;
end BFSB1;

protected function BFSBphase
"function helper for BFSB, traverses all colums and perform a BFSB phase on each
 author: Frenkel TUD 2012-03"
  input list<Integer> queue;
  input Integer rowmark;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> parentcolum;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> nextQueue;
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums "This list stores all visited collums, if no augmenting path is found
                                         it could be used to prune the nodes, if a path is found the list is empty";
algorithm
  outVisitedColums :=
  match (queue,rowmark,i,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2,nextQueue,inVisitedColums)
    local
      list<Integer> rest,queue1,rows;
      Integer c;
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,{},_) then inVisitedColums;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_)
       then
         BFSBphase(nextQueue,rowmark,i,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2,{},inVisitedColums);
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        rows = List.select(m[c], Util.intPositive);
        (queue1,b) = BFSBtraverseRows(rows,nextQueue,rowmark,i,c,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2);
      then
        BFSBphase1(b,rest,rowmark,i,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2,queue1,c::inVisitedColums);
    else
      equation
        Error.addInternalError("function BFSBphase failed in equation " + intString(i), sourceInfo());
      then
        fail();

  end match;
end BFSBphase;

protected function BFSBphase1
"function helper for BFSB, traverses all colums and perform a BFSB phase on each
 author: Frenkel TUD 2012-03"
  input Boolean inPathFound;
  input list<Integer> queue;
  input Integer rowmark;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> parentcolum;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> nextQueue;
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums;
algorithm
  outVisitedColums :=
  match (inPathFound,queue,rowmark,i,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2,nextQueue,inVisitedColums)
    case (true,_,_,_,_,_,_,_,_,_,_,_,_,_) then {};
    case (false,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        BFSBphase(queue,rowmark,i,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2,nextQueue,inVisitedColums);
    else
      equation
        Error.addInternalError("function BFSBphase1 failed", sourceInfo());
      then
        fail();
  end match;
end BFSBphase1;

protected function BFSBtraverseRows
"function helper for BFSB, traverses all vars of a equations and search a augmenting path
 author: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> queue;
  input Integer rowmark;
  input Integer i;
  input Integer c;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> parentcolum;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output list<Integer> outEqnqueue;
  output Boolean pathFound;
algorithm
  (outEqnqueue,pathFound):=
  matchcontinue (rows,queue,rowmark,i,c,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2)
    local
      list<Integer> rest,queue1,queue2;
      Integer rc,r;
      Boolean b;
      case ({},_,_,_,_,_,_,_,_,_,_,_,_) then (listReverse(queue),false);
    case (r::_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is unmatched -> augmenting path found
        true = intLt(ass2[r],0);
        BFSBreasign(i,c,parentcolum,r,ass1,ass2);
      then
        ({},true);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is matched
        rc = ass2[r];
        false = intLt(rc,0);
        queue1 = BFSBenque(queue,rowmark,c,rc,r,intLt(rowmarks[r],rowmark),rowmarks,parentcolum);
        (queue2,b) = BFSBtraverseRows(rest,queue1,rowmark,i,c,nv,ne,m,mT,rowmarks,parentcolum,ass1,ass2);
      then
        (queue2,b);
    else
      equation
        Error.addInternalError("function BFSBtraverseRows failed in equation " + intString(i), sourceInfo());
      then
        fail();

  end matchcontinue;
end BFSBtraverseRows;

protected function BFSBreasign
"function helper for BFSB, reasignment(rematching) allong the augmenting path
 remove all edges from the assignments that are in the path
 add all other edges to the assignment
 author: Frenkel TUD 2012-03"
  input Integer i;
  input Integer c;
  input array<Integer> parentcolum;
  input Integer l;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
algorithm
  _ := matchcontinue (i,c,parentcolum,l,ass1,ass2)
    local
      Integer r;
    case (_,_,_,_,_,_)
      equation
        true = intEq(i,c);
        arrayUpdate(ass1,c,l);
        arrayUpdate(ass2,l,c);
      then ();
    case (_,_,_,_,_,_)
      equation
        r = ass1[c];
        arrayUpdate(ass1,c,l);
        arrayUpdate(ass2,l,c);
        BFSBreasign(i,parentcolum[r],parentcolum,r,ass1,ass2);
      then
        ();
    else
      equation
        Error.addInternalError("function BFSBreasign failed", sourceInfo());
      then
        fail();
   end matchcontinue;
end BFSBreasign;

protected function BFSBenque
"function helper for BFSB, enque a collum if the row is not visited
 author: Frenkel TUD 2012-03"
  input list<Integer> queue;
  input Integer rowmark;
  input Integer c;
  input Integer rc;
  input Integer r;
  input Boolean visited;
  input array<Integer> rowmarks;
  input array<Integer> parentcolum;
  output list<Integer> outEqnqueue;
algorithm
  outEqnqueue:=
  match (queue,rowmark,c,rc,r,visited,rowmarks,parentcolum)
    case (_,_,_,_,_,false,_,_) then queue;
    case (_,_,_,_,_,true,_,_)
      equation
        // mark row
        arrayUpdate(rowmarks,r,rowmark);
        // store parent colum
        arrayUpdate(parentcolum,r,c);
      then
        (rc::queue);
    else
      equation
        Error.addInternalError("function BFSBenque failed", sourceInfo());
      then
        fail();

  end match;
end BFSBenque;


public function DFSB
"        complexity O(n*tau)
 author: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> rowmarks;

    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        rowmarks = arrayCreate(nvars,-1);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        _ = cheapmatchingalgorithm(nvars,neqns,m,mt,vec1,vec2,false);
        (vec1,vec2,syst,shared,arg) = DFSB1(1,1,nvars,neqns,m,mt,rowmarks,vec1,vec2,isyst,ishared,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);

    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);

    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
         Debug.trace("- Matching.BFSB failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end DFSB;

protected function DFSB1
"function helper for DFSB, traverses all colums and perform a DFSB phase on each
 author: Frenkel TUD 2012-03"
  input Integer i;
  input Integer rowmark;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  matchcontinue (i,rowmark,nv,ne,m,mT,rowmarks,ass1,ass2,isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      list<Integer> visitedcolums;
      BackendDAE.IncidenceMatrix m1,mt1;
      Integer nv_1,ne_1,i_1;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2,rowmarks1;
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true=intGt(i,ne);
      then
        (ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // not assigned
        false = intGt(ass1[i],0);
        // search augmenting paths
        visitedcolums = DFSBphase({i},rowmark,i,nv,ne,m,mT,rowmarks,ass1,ass2,{i});
        // if visitedcolums is not zero matching fails -> try index reduction and matching aggain
        // if visitedcolums is not zero matching fails -> try index reduction and matching aggain
        (_,i_1,syst as BackendDAE.EQSYSTEM(m=SOME(m1),mT=SOME(mt1)),shared,nv_1,ne_1,ass1_1,ass2_1,arg) = reduceIndexifNecessary(visitedcolums,i,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        rowmarks1 = assignmentsArrayExpand(rowmarks,nv_1,arrayLength(rowmarks),-1);
        (ass1_2,ass2_2,syst,shared,arg) = DFSB1(i_1,rowmark+1,nv_1,ne_1,m1,mt1,rowmarks1,ass1_1,ass2_1,syst,shared,inMatchingOptions,sssHandler,arg);
      then
        (ass1_2,ass2_2,syst,shared,arg);

    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(ass1[i],0);
        (ass1_1,ass2_1,syst,shared,arg) = DFSB1(i+1,rowmark,nv,ne,m,mT,rowmarks,ass1,ass2,isyst,ishared,inMatchingOptions,sssHandler,inArg);
      then
        (ass1_1,ass2_1,syst,shared,arg);

    else
      equation
        Error.addInternalError("function DFSB1 failed in equation " + intString(i), sourceInfo());
      then
        fail();

  end matchcontinue;
end DFSB1;

protected function DFSBphase
"function helper for DFSB, traverses all colums and perform a DFSB phase on each
 author: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer i;
  input Integer c;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums "This list stores all visited collums, if no augmenting path is found
                                         it could be used to prune the nodes, if a path is found the list is empty";
algorithm
  outVisitedColums :=
  match (stack,i,c,nv,ne,m,mT,rowmarks,ass1,ass2,inVisitedColums)
    local
      list<Integer> rows;
    case ({},_,_,_,_,_,_,_,_,_,_) then inVisitedColums;
    case (_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        rows = List.select(m[c], Util.intPositive);
      then
        DFSBtraverseRows(rows,stack,i,nv,ne,m,mT,rowmarks,ass1,ass2,inVisitedColums);
    else
      equation
        Error.addInternalError("function DFSBphase failed in equation " + intString(c), sourceInfo());
      then
        fail();

  end match;
end DFSBphase;

protected function DFSBtraverseRows
"function helper for DFSB, traverses all vars of a equations and search a augmenting path
 author: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> stack;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums;
algorithm
  outVisitedColums:=
  matchcontinue (rows,stack,i,nv,ne,m,mT,rowmarks,ass1,ass2,inVisitedColums)
    local
      list<Integer> rest,visitedColums;
      Integer rc,r;
    case ({},_,_,_,_,_,_,_,_,_,_) then inVisitedColums;
    case (r::_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is unmatched -> augmenting path found
        true = intLt(ass2[r],0);
        DFSBreasign(stack,r,ass1,ass2);
      then
        {};
    case (r::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is matched
        rc = ass2[r];
        false = intLt(rc,0);
        true = intLt(rowmarks[r],i);
        arrayUpdate(rowmarks,r,i);
        visitedColums = DFSBphase(rc::stack,i,rc,nv,ne,m,mT,rowmarks,ass1,ass2,rc::inVisitedColums);
      then
        DFSBtraverseRows1(rest,stack,i,nv,ne,m,mT,rowmarks,ass1,ass2,visitedColums);
    case (_::rest,_,_,_,_,_,_,_,_,_,_)
      then
        DFSBtraverseRows(rest,stack,i,nv,ne,m,mT,rowmarks,ass1,ass2,inVisitedColums);
    else
      equation
        Error.addInternalError("function DFSBtraverseRows failed", sourceInfo());
      then
        fail();

  end matchcontinue;
end DFSBtraverseRows;

protected function DFSBtraverseRows1
"function helper for DFSBtraverseRows
 author: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> stack;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums;
algorithm
  outVisitedColums:=
  match (rows,stack,i,nv,ne,m,mT,rowmarks,ass1,ass2,inVisitedColums)
    case (_,_,_,_,_,_,_,_,_,_,{}) then inVisitedColums;
    else DFSBtraverseRows(rows,stack,i,nv,ne,m,mT,rowmarks,ass1,ass2,inVisitedColums);
  end match;
end DFSBtraverseRows1;

protected function DFSBreasign
"function helper for DFSB, reasignment(rematching) allong the augmenting path
 remove all edges from the assignments that are in the path
 add all other edges to the assignment
 author: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer r;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
algorithm
  _ := match (stack,r,ass1,ass2)
    local
      Integer c,rc;
      list<Integer> rest;
    case ({},_,_,_) then ();
    case (c::rest,_,_,_)
      equation
        rc = ass1[c];
        arrayUpdate(ass1,c,r);
        arrayUpdate(ass2,r,c);
        DFSBreasign(rest,rc,ass1,ass2);
      then ();
   end match;
end DFSBreasign;

public function MC21A
"        complexity O(n*tau)
 author: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> rowmarks,lookahead;

    case (syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        rowmarks = arrayCreate(nvars,-1);
        lookahead = arrayCreate(neqns,0);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        _ = cheapmatchingalgorithm(nvars,neqns,m,mt,vec1,vec2,false);
        (vec1,vec2,syst,shared,arg) = MC21A1(1,1,nvars,neqns,m,mt,rowmarks,lookahead,vec1,vec2,isyst,ishared,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.MC21A failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end MC21A;

protected function MC21A1
"function helper for MC21A, traverses all colums and perform a MC21A phase on each
 author: Frenkel TUD 2012-03"
  input Integer i;
  input Integer rowmark;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  matchcontinue (i,rowmark,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,isyst,ishared,inMatchingOptions,sssHandler,inArg)
    local
      list<Integer> visitedcolums,changedEqns;
      BackendDAE.IncidenceMatrix m1,mt1;
      Integer nv_1,ne_1,i_1;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2,rowmarks1,lookahead1;

    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true=intGt(i,ne);
      then
        (ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // not assigned
        false = intGt(ass1[i],0);
        // search augmenting paths
        visitedcolums = MC21Aphase({i},rowmark,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,{i});
        // if visitedcolums is not zero matching fails -> try index reduction and matching aggain
        (changedEqns,i_1,syst as BackendDAE.EQSYSTEM(m=SOME(m1),mT=SOME(mt1)),shared,nv_1,ne_1,ass1_1,ass2_1,arg) = reduceIndexifNecessary(visitedcolums,i,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        (rowmarks1,lookahead1) = MC21A1fixArrays(visitedcolums,nv_1,ne_1,rowmarks,lookahead,changedEqns);
        (ass1_2,ass2_2,syst,shared,arg) = MC21A1(i_1,rowmark+1,nv_1,ne_1,m1,mt1,rowmarks1,lookahead1,ass1_1,ass2_1,syst,shared,inMatchingOptions,sssHandler,arg);
      then
        (ass1_2,ass2_2,syst,shared,arg);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(ass1[i],0);
        (ass1_1,ass2_1,syst,shared,arg) = MC21A1(i+1,rowmark,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,isyst,ishared,inMatchingOptions,sssHandler,inArg);
      then
        (ass1_1,ass2_1,syst,shared,arg);
    else
      equation
        Error.addInternalError("function MC21A1 failed in equation " + intString(i), sourceInfo());
      then
        fail();
  end matchcontinue;
end MC21A1;

protected function MC21A1fixArrays
"function: MC21A1fixArrays, fixes lookahead and rowmarks after system has been index reduced
  author: Frenkel TUD 2012-04"
  input list<Integer> meqns "Marked Equations for Index Reduction";
  input Integer nv;
  input Integer ne;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input list<Integer> changedEqns;
  output array<Integer> outrowmarks;
  output array<Integer> outlookahead;
algorithm
  (outrowmarks,outlookahead):=
  match (meqns,nv,ne,rowmarks,lookahead,changedEqns)
    local
      Integer memsize;
      array<Integer> rowmarks1,lookahead1;
    case ({},_,_,_,_,_) then (rowmarks,lookahead);
    case (_::_,_,_,_,_,_)
      equation
        memsize = arrayLength(rowmarks);
        rowmarks1 = assignmentsArrayExpand(rowmarks,nv,memsize,-1);
        lookahead1 = assignmentsArrayExpand(lookahead,ne,memsize,0);
        MC21A1fixArray(changedEqns,lookahead1);
      then
        (rowmarks1,lookahead1);
    else
      equation
        Error.addInternalError("function MC21A1fixArrays failed", sourceInfo());
      then
        fail();
  end match;
end MC21A1fixArrays;

protected function MC21A1fixArray
"author: Frenkel TUD 2012-04"
  input list<Integer> meqns "Marked Equations for Index Reduction";
  input array<Integer> arr;
algorithm
  _ :=
  match (meqns,arr)
    local
      Integer e;
      list<Integer> rest;
    case ({},_) then ();
    case (e::rest,_)
      equation
        arrayUpdate(arr,e,0);
        MC21A1fixArray(rest,arr);
      then
        ();
    else
      equation
        Error.addInternalError("function MC21A1fixArray failed", sourceInfo());
      then
        fail();
  end match;
end MC21A1fixArray;

protected function MC21Aphase
"function helper for MC21A, traverses all colums and perform a MC21A phase on each
 author: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer i;
  input Integer c;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums "This list stores all visited collums, if no augmenting path is found
                                         it could be used to prune the nodes, if a path is found the list is empty";
algorithm
  outVisitedColums :=
  match (stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums)
    local
      list<Integer> rows;
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then inVisitedColums;
    case (_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        rows = List.select(m[c], Util.intPositive);
        b = intLt(lookahead[c],listLength(rows));
     then
        MC21Achecklookahead(b,rows,stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums);
    else
      equation
        Error.addInternalError("function MC21Aphase failed in equation " + intString(c), sourceInfo());
      then
        fail();
  end match;
end MC21Aphase;

protected function MC21Achecklookahead
"function helper for MC21A, traverses all vars of a equations and search a augmenting path
 author: Frenkel TUD 2012-03"
  input Boolean dolookahaed;
  input list<Integer> rows;
  input list<Integer> stack;
  input Integer i;
  input Integer c;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums;
algorithm
  outVisitedColums:=
  match (dolookahaed,rows,stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums)
    case (true,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        MC21AtraverseRowsUnmatched(rows,rows,stack,i,c,listLength(rows),nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums);
    else
      MC21AtraverseRows(rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums);
  end match;
end MC21Achecklookahead;

protected function MC21AtraverseRowsUnmatched
"function helper for MC21A, traverses all vars of a equations and search a augmenting path
 author: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> rows1;
  input list<Integer> stack;
  input Integer i;
  input Integer c;
  input Integer l;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums;
algorithm
  outVisitedColums:=
  matchcontinue (rows,rows1,stack,i,c,l,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums)
    local
      list<Integer> rest;
      Integer r;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        arrayUpdate(lookahead,c,l);
       then
         MC21AtraverseRows(rows1,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums);
    case (r::_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is unmatched -> augmenting path found
        true = intLt(ass2[r],0);
        DFSBreasign(stack,r,ass1,ass2);
      then
        {};
    case (_::rest,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        MC21AtraverseRowsUnmatched(rest,rows1,stack,i,c,l,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums);
  end matchcontinue;
end MC21AtraverseRowsUnmatched;

protected function MC21AtraverseRows
"function helper for MC21A, traverses all vars of a equations and search a augmenting path
 author: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> stack;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums;
algorithm
  outVisitedColums:=
  matchcontinue (rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums)
    local
      list<Integer> rest,visitedColums;
      Integer rc,r;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then inVisitedColums;
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is matched
        rc = ass2[r];
        false = intLt(rc,0);
        true = intLt(rowmarks[r],i);
        arrayUpdate(rowmarks,r,i);
        visitedColums = MC21Aphase(rc::stack,i,rc,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,rc::inVisitedColums);
      then
        MC21AtraverseRows1(rest,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,visitedColums);
    case (_::rest,_,_,_,_,_,_,_,_,_,_,_)
      then
        MC21AtraverseRows(rest,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums);
    else
      equation
        Error.addInternalError("function MC21AtraverseRows failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end MC21AtraverseRows;

protected function MC21AtraverseRows1
"function helper for MC21AtraverseRows
 author: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> stack;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> inVisitedColums;
  output list<Integer> outVisitedColums;
algorithm
  outVisitedColums:=
  match (rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums)
    case (_,_,_,_,_,_,_,_,_,_,_,{}) then inVisitedColums;
    else MC21AtraverseRows(rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inVisitedColums);
  end match;
end MC21AtraverseRows1;


public function PF
"        complexity O(n*tau)
 author: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> rowmarks,lookahead;
      list<Integer> unmatched;
    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        rowmarks = arrayCreate(nvars,-1);
        lookahead = arrayCreate(neqns,0);
        unmatched = cheapmatchingalgorithm(nvars,neqns,m,mt,vec1,vec2,true);
        (vec1,vec2,syst,shared,arg) = PF1(0,unmatched,rowmarks,lookahead,isyst,ishared,nvars,neqns,vec1,vec2,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.PF failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end PF;

protected function PF1
"function: PF1, helper for PF
  author: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> unmatched;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  match (i,unmatched,rowmarks,lookahead,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt;
      Integer nv_1,ne_1,i_1;
      list<Integer> unmatched1;
      list<list<Integer>> meqns;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2,rowmarks1,lookahead1;
    case (_,{},_,_,_,_,_,_,_,_,_,_,_)
      then
        (ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_)
      equation
        (i_1,unmatched1) = PFaugmentmatching(i,unmatched,nv,ne,m,mt,rowmarks,lookahead,ass1,ass2,listLength(unmatched),{});
        meqns = getEqnsforIndexReduction(unmatched1,ne,m,mt,ass1,ass2,inArg);
        (unmatched1,rowmarks1,lookahead1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg) = PF2(meqns,unmatched1,{},rowmarks,lookahead,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        (ass1_2,ass2_2,syst,shared,arg1) = PF1(i_1+1,unmatched1,rowmarks1,lookahead1,syst,shared,nv_1,ne_1,ass1_1,ass2_1,inMatchingOptions,sssHandler,arg);
      then
        (ass1_2,ass2_2,syst,shared,arg1);
  end match;
end PF1;

protected function PF2
"function: PF2, helper for PF
  author: Frenkel TUD 2012-03"
  input list<list<Integer>> meqns "Marked Equations for Index Reduction";
  input list<Integer> unmatched;
  input list<Integer> changedEqns;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output list<Integer> outunmatched;
  output array<Integer> outrowmarks;
  output array<Integer> outlookahead;
  output Integer nvars;
  output Integer neqns;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outunmatched,outrowmarks,outlookahead,nvars,neqns,outAss1,outAss2,osyst,oshared,outArg):=
  match (meqns,unmatched,changedEqns,rowmarks,lookahead,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      Integer nv_1,ne_1;
      list<Integer> unmatched1;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> ass1_1,ass2_1,rowmarks1,lookahead1;

    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        (unmatched,rowmarks,lookahead,nv,ne,ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,_,_,_,_,_,_,(BackendDAE.INDEX_REDUCTION(),_),_,_)
      equation
        (unmatched1,_,syst,shared,ass2_1,ass1_1,arg) = sssHandler(meqns,0,isyst,ishared,ass2,ass1,inArg);
        ne_1 = BackendDAEUtil.systemSize(syst);
        nv_1 = BackendVariable.daenumVariables(syst);
        ass1_1 = assignmentsArrayExpand(ass1_1,ne_1,ne,-1);
        ass2_1 = assignmentsArrayExpand(ass2_1,nv_1,nv,-1);
        rowmarks1 = assignmentsArrayExpand(rowmarks,nv_1,nv,-1);
        lookahead1 = assignmentsArrayExpand(lookahead,ne_1,ne,0);
        MC21A1fixArray(unmatched1,lookahead1);
      then
        (unmatched1,rowmarks1,lookahead1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        singularSystemError(meqns,0,isyst,ishared,ass1,ass2,inArg);
      then
        fail();
  end match;
end PF2;

protected function PFaugmentmatching
"function helper for PFaugmentmatching, traverses all unmatched
 colums and perform one pass of the augmenting proceure
 author: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> U;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input Integer previousUnmatched;
  input list<Integer> unMatched;
  output Integer outI;
  output list<Integer> outUnmatched;
algorithm
  (outI,outUnmatched):=
  matchcontinue (i,U,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,previousUnmatched,unMatched)
    local
      list<Integer> rest,unmatched;
      Integer c,i_1;
      Boolean b;
    case (_,{},_,_,_,_,_,_,_,_,_,_)
      equation
        // no augmenting path is found in pass
        true=intEq(previousUnmatched,listLength(unMatched));
      then
        (i,unMatched);
    case (_,{},_,_,_,_,_,_,_,_,_,_)
      equation
       // augmenting path is found in pass, next round
       (i_1,unmatched) = PFaugmentmatching(i+1,unMatched,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,listLength(unMatched),{});
      then
        (i_1,unmatched);
    case (_,c::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(ass1[c],-1);
        (i_1,unmatched) = PFaugmentmatching(i,rest,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,previousUnmatched,unMatched);
      then
        (i_1,unmatched);
    case (_,c::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        b = PFphase({c},i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);
        unmatched = List.consOnTrue(not b, c, unMatched);
        (i_1,unmatched) = PFaugmentmatching(i,rest,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,previousUnmatched,unmatched);
      then
        (i_1,unmatched);
    else
      equation
        Error.addInternalError("function PFaugmentmatching failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end PFaugmentmatching;

protected function PFphase
"function helper for PF, traverses all colums and perform a PF phase on each
 author: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer i;
  input Integer c;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output Boolean matched;
algorithm
  matched :=
  match (stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2)
    local
      list<Integer> rows;
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_) then false;
    case (_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        rows = List.select(m[c], Util.intPositive);
        b = intLt(lookahead[c],listLength(rows));
      then
        PFchecklookahead(b,rows,stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);
    else
      equation
        Error.addInternalError("function PFphase failed in equation " + intString(c), sourceInfo());
      then
        fail();

  end match;
end PFphase;

protected function PFchecklookahead
"function helper for PF, traverses all vars of a equations and search a augmenting path
 author: Frenkel TUD 2012-03"
  input Boolean dolookahaed;
  input list<Integer> rows;
  input list<Integer> stack;
  input Integer i;
  input Integer c;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output Boolean matched;
algorithm
  matched:=
  match (dolookahaed,rows,stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2)
    case (true,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        PFtraverseRowsUnmatched(rows,rows,stack,i,c,listLength(rows),nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);
    else
      PFtraverseRows(rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);
  end match;
end PFchecklookahead;

protected function PFtraverseRowsUnmatched
"function helper for PF, traverses all vars of a equations and search a augmenting path
 author: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> rows1;
  input list<Integer> stack;
  input Integer i;
  input Integer c;
  input Integer l;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output Boolean matched;
algorithm
  matched:=
  matchcontinue (rows,rows1,stack,i,c,l,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2)
    local
      list<Integer> rest;
      Integer r;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        arrayUpdate(lookahead,c,l);
       then
         PFtraverseRows(rows1,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);
    case (r::_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is unmatched -> augmenting path found
        true = intLt(ass2[r],0);
        DFSBreasign(stack,r,ass1,ass2);
      then
        true;
    case (_::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        PFtraverseRowsUnmatched(rest,rows1,stack,i,c,l,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);
  end matchcontinue;
end PFtraverseRowsUnmatched;

protected function PFtraverseRows
"function helper for PF, traverses all vars of a equations and search a augmenting path
 author: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> stack;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output Boolean matched;
algorithm
  matched:=
  matchcontinue (rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2)
    local
      list<Integer> rest;
      Integer rc,r;
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_) then false;
    case (r::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is matched
        rc = ass2[r];
        false = intLt(rc,0);
        false = intEq(rowmarks[r],i);
        arrayUpdate(rowmarks,r,i);
        b = PFphase(rc::stack,i,rc,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);
      then
        PFtraverseRows1(rest,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,b);
    case (_::rest,_,_,_,_,_,_,_,_,_,_)
      then
        PFtraverseRows(rest,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);
    else
      equation
        Error.addInternalError("function PFtraverseRows failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end PFtraverseRows;

protected function PFtraverseRows1
"function helper for PFtraverseRows
 author: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> stack;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input Boolean inMatched;
  output Boolean matched;
algorithm
  matched:=
  match (rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inMatched)
    case (_,_,_,_,_,_,_,_,_,_,_,true) then inMatched;
    else PFtraverseRows(rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2);
  end match;
end PFtraverseRows1;

public function PFPlus
"        complexity O(n*tau)
 author: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns,i;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> rowmarks,lookahead;
      list<Integer> unmatched;
    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        rowmarks = arrayCreate(nvars,-1);
        lookahead = arrayCreate(neqns,0);
        unmatched = cheapmatchingalgorithm(nvars,neqns,m,mt,vec1,vec2,true);
        (_,vec1,vec2,syst,shared,arg) = PFPlus1(0,unmatched,rowmarks,lookahead,isyst,ishared,nvars,neqns,vec1,vec2,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.PFPlus failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end PFPlus;

protected function PFPlus1
"function: PFPlus1, helper for PFPlus
  author: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> unmatched;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output Integer outI;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outI,outAss1,outAss2,osyst,oshared,outArg):=
  match (i,unmatched,rowmarks,lookahead,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt;
      Integer nv_1,ne_1,i_1;
      list<Integer> unmatched1;
      list<list<Integer>> meqns;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2,rowmarks1,lookahead1;
    case (_,{},_,_,_,_,_,_,_,_,_,_,_)
      then
        (i,ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_)
      equation
        (i_1,unmatched1) = PFPlusaugmentmatching(i,unmatched,nv,ne,m,mt,rowmarks,lookahead,ass1,ass2,listLength(unmatched),{},false);
        meqns = getEqnsforIndexReduction(unmatched1,ne,m,mt,ass1,ass2,inArg);
        (unmatched1,rowmarks1,lookahead1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg) = PF2(meqns,unmatched1,{},rowmarks,lookahead,syst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        (i_1,ass1_2,ass2_2,syst,shared,arg1) = PFPlus1(i_1+1,unmatched1,rowmarks1,lookahead1,syst,shared,nv_1,ne_1,ass1_1,ass2_1,inMatchingOptions,sssHandler,arg);
      then
        (i_1,ass1_2,ass2_2,syst,shared,arg1);
  end match;
end PFPlus1;

protected function PFPlusaugmentmatching
"function helper for PFPlusaugmentmatching, traverses all unmatched
 colums and perform one pass of the augmenting proceure
 author: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> U;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input Integer previousUnmatched;
  input list<Integer> unMatched;
  input Boolean reverseRows;
  output Integer outI;
  output list<Integer> outUnMatched;
algorithm
  (outI,outUnMatched) :=
  matchcontinue (i,U,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,previousUnmatched,unMatched,reverseRows)
    local
      list<Integer> rest,unmatched;
      Integer c,i_1;
      Boolean b;
    case (_,{},_,_,_,_,_,_,_,_,_,_,_)
      equation
        // no augmenting path is found in pass
        true=intEq(previousUnmatched,listLength(unMatched));
      then
        (i,unMatched);
    case (_,{},_,_,_,_,_,_,_,_,_,_,_)
      equation
       // augmenting path is found in pass, next round
       (i_1,unmatched) = PFPlusaugmentmatching(i+1,unMatched,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,listLength(unMatched),{},reverseRows);
      then
        (i_1,unmatched);
    case (_,c::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(ass1[c],-1);
        (i_1,unmatched) = PFPlusaugmentmatching(i,rest,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,previousUnmatched,unMatched,reverseRows);
      then
        (i_1,unmatched);
    case (_,c::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        b = PFPlusphase({c},i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
        unmatched = List.consOnTrue(not b, c, unMatched);
        (i_1,unmatched) = PFPlusaugmentmatching(i,rest,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,previousUnmatched,unmatched,not reverseRows);
      then
        (i_1,unmatched);
    else
      equation
        Error.addInternalError("function PFPlusaugmentmatching failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end PFPlusaugmentmatching;

protected function PFPlusphase
"function helper for PFPlus, traverses all colums and perform a PFPlus phase on each
 author: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer i;
  input Integer c;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input Boolean reverseRows;
  output Boolean matched;
algorithm
  matched :=
  match (stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows)
    local
      list<Integer> rows;
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then false;
    case (_,_,_,_,_,_,_,_,_,_,_,false)
      equation
        // traverse all adiacent rows
        rows = List.select(m[c], Util.intPositive);
        b = intLt(lookahead[c],listLength(rows));
     then
        PFPluschecklookahead(b,rows,stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
    case (_,_,_,_,_,_,_,_,_,_,_,true)
      equation
        // traverse all adiacent rows
        rows = List.select(m[c], Util.intPositive);
        b = intLt(lookahead[c],listLength(rows));
      then
        PFPluschecklookahead(b,listReverse(rows),stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
    else
      equation
        Error.addInternalError("function PFPlusphase failed in equation " + intString(c), sourceInfo());
      then
        fail();

  end match;
end PFPlusphase;

protected function PFPluschecklookahead
"function helper for PFPlus, traverses all vars of a equations and search a augmenting path
 author: Frenkel TUD 2012-03"
  input Boolean dolookahaed;
  input list<Integer> rows;
  input list<Integer> stack;
  input Integer i;
  input Integer c;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input Boolean reverseRows;
  output Boolean matched;
algorithm
  matched:=
  match (dolookahaed,rows,stack,i,c,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows)
    case (true,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        PFPlustraverseRowsUnmatched(rows,rows,stack,i,c,listLength(rows),nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
    else
      PFPlustraverseRows(rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
  end match;
end PFPluschecklookahead;

protected function PFPlustraverseRowsUnmatched
"function helper for PFPlus, traverses all vars of a equations and search a augmenting path
 author: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> rows1;
  input list<Integer> stack;
  input Integer i;
  input Integer c;
  input Integer l;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input Boolean reverseRows;
  output Boolean matched;
algorithm
  matched:=
  matchcontinue (rows,rows1,stack,i,c,l,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows)
    local
      list<Integer> rest;
      Integer r;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        arrayUpdate(lookahead,c,l);
       then
         PFPlustraverseRows(rows1,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
    case (r::_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is unmatched -> augmenting path found
        true = intLt(ass2[r],0);
        DFSBreasign(stack,r,ass1,ass2);
      then
        true;
    case (_::rest,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        PFPlustraverseRowsUnmatched(rest,rows1,stack,i,c,l,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
  end matchcontinue;
end PFPlustraverseRowsUnmatched;

protected function PFPlustraverseRows
"function helper for PFPlus, traverses all vars of a equations and search a augmenting path
 author: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> stack;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input Boolean reverseRows;
  output Boolean matched;
algorithm
  matched:=
  matchcontinue (rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows)
    local
      list<Integer> rest;
      Integer rc,r;
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then false;
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is matched
        rc = ass2[r];
        false = intLt(rc,0);
        false = intEq(rowmarks[r],i);
        arrayUpdate(rowmarks,r,i);
        b = PFPlusphase(rc::stack,i,rc,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
      then
        PFPlustraverseRows1(rest,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,b,reverseRows);
    case (_::rest,_,_,_,_,_,_,_,_,_,_,_)
      then
        PFPlustraverseRows(rest,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
    else
      equation
        Error.addInternalError("function PFPlustraverseRows failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end PFPlustraverseRows;

protected function PFPlustraverseRows1
"function helper for PFPlustraverseRows
 author: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> stack;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> lookahead;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input Boolean inMatched;
  input Boolean reverseRows;
  output Boolean matched;
algorithm
  matched:=
  match (rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,inMatched,reverseRows)
    case (_,_,_,_,_,_,_,_,_,_,_,true,_) then inMatched;
    else PFPlustraverseRows(rows,stack,i,nv,ne,m,mT,rowmarks,lookahead,ass1,ass2,reverseRows);
  end match;
end PFPlustraverseRows1;

public function HK
"        complexity O(sqrt(n)*tau)
 author: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> rowmarks,level,collummarks;
      list<Integer> unmatched;
    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        rowmarks = arrayCreate(nvars,-1);
        collummarks = arrayCreate(neqns,-1);
        level = arrayCreate(neqns,-1);
        unmatched = cheapmatchingalgorithm(nvars,neqns,m,mt,vec1,vec2,true);
        (vec1,vec2,syst,shared,arg) = HK1(0,unmatched,rowmarks,collummarks,level,isyst,ishared,nvars,neqns,vec1,vec2,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.HK failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end HK;

protected function HK1
"function: HK1, helper for HK
  author: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> unmatched;
  input array<Integer> rowmarks;
  input array<Integer> collummarks;
  input array<Integer> level;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  match (i,unmatched,rowmarks,collummarks,level,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt;
      Integer nv_1,ne_1,i_1;
      list<Integer> unmatched1;
      list<list<Integer>> meqns;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2,rowmarks1,collummarks1,level1;
    case (_,{},_,_,_,_,_,_,_,_,_,_,_,_)
      then
        (ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_)
      equation
        (i_1,unmatched1) = HKphase(i,unmatched,nv,ne,m,mt,rowmarks,collummarks,level,ass1,ass2,listLength(unmatched),{});
        meqns = getEqnsforIndexReduction(unmatched1,ne,m,mt,ass1,ass2,inArg);
        (unmatched1,rowmarks1,collummarks1,level1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg) = HK2(meqns,unmatched1,{},rowmarks,collummarks,level,syst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        (ass1_2,ass2_2,syst,shared,arg1) = HK1(i_1+1,unmatched1,rowmarks1,collummarks1,level1,syst,shared,nv_1,ne_1,ass1_1,ass2_1,inMatchingOptions,sssHandler,arg);
      then
        (ass1_2,ass2_2,syst,shared,arg1);
  end match;
end HK1;

protected function HK2
"function: HK2, helper for HK
  author: Frenkel TUD 2012-03"
  input list<list<Integer>> meqns "Marked Equations for Index Reduction";
  input list<Integer> unmatched;
  input list<Integer> changedEqns;
  input array<Integer> rowmarks;
  input array<Integer> collummarks;
  input array<Integer> level;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output list<Integer> outunmatched;
  output array<Integer> outrowmarks;
  output array<Integer> outcollummarks;
  output array<Integer> outlevel;
  output Integer nvars;
  output Integer neqns;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outunmatched,outrowmarks,outcollummarks,outlevel,nvars,neqns,outAss1,outAss2,osyst,oshared,outArg):=
  match (meqns,unmatched,changedEqns,rowmarks,collummarks,level,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      Integer nv_1,ne_1;
      list<Integer> unmatched1;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> ass1_1,ass2_1,rowmarks1,collummarks1,level1;

    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        (unmatched,rowmarks,collummarks,level,nv,ne,ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,_,_,_,_,_,_,_,(BackendDAE.INDEX_REDUCTION(),_),_,_)
      equation
        (unmatched1,_,syst,shared,ass2_1,ass1_1,arg) = sssHandler(meqns,0,isyst,ishared,ass2,ass1,inArg);
        ne_1 = BackendDAEUtil.systemSize(syst);
        nv_1 = BackendVariable.daenumVariables(syst);
        ass1_1 = assignmentsArrayExpand(ass1_1,ne_1,arrayLength(ass1),-1);
        ass2_1 = assignmentsArrayExpand(ass2_1,nv_1,arrayLength(ass2),-1);
        rowmarks1 = assignmentsArrayExpand(rowmarks,nv_1,arrayLength(rowmarks),-1);
        collummarks1 = assignmentsArrayExpand(collummarks,ne_1,arrayLength(collummarks),-1);
        level1 = assignmentsArrayExpand(level,ne_1,arrayLength(level),-1);
      then
        (unmatched1,rowmarks1,collummarks1,level1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        singularSystemError(meqns,0,isyst,ishared,ass1,ass2,inArg);
      then
        fail();
  end match;
end HK2;

protected function HKphase
"function helper for HK, traverses all unmatched
 colums and run a BFS and DFS
 author: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> U;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> collummarks;
  input array<Integer> level;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input Integer previousUnmatched;
  input list<Integer> unMatched;
  output Integer outI;
  output list<Integer> outunMatched;
algorithm
  (outI,outunMatched):=
  matchcontinue (i,U,nv,ne,m,mT,rowmarks,collummarks,level,ass1,ass2,previousUnmatched,unMatched)
    local
      list<Integer> unmatched;
      list<tuple<Integer,Integer>> rows;
      Integer i_1;
    case (_,{},_,_,_,_,_,_,_,_,_,_,_)
      equation
        // no augmenting path is found in phase
        true=intEq(previousUnmatched,listLength(unMatched));
      then
        (i,unMatched);
    case (_,{},_,_,_,_,_,_,_,_,_,_,_)
      equation
        // augmenting path is found in phase, next round
        (i_1,unmatched) = HKphase(i+1,unMatched,nv,ne,m,mT,rowmarks,collummarks,level,ass1,ass2,listLength(unMatched),{});
      then
        (i_1,unmatched);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // BFS phase to get the level information
        rows = HKBFS(U,nv,ne,m,mT,rowmarks,i,level,NONE(),ass1,ass2,{});
        // DFS to match
        _ = HKDFS(rows,i,nv,ne,m,mT,collummarks,level,ass1,ass2,{});
        // remove matched collums from U
        unmatched = HKgetUnmatched(U,ass1,{});
        (i_1,unmatched) = HKphase(i,{},nv,ne,m,mT,rowmarks,collummarks,level,ass1,ass2,previousUnmatched,unmatched);
      then
        (i_1,unmatched);
    else
      equation
        Error.addInternalError("function HKphase failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end HKphase;

protected function HKgetUnmatched
  input list<Integer> U;
  input array<Integer> ass1 "eqn := ass1[var]";
  input list<Integer> inUnmatched;
  output list<Integer> outUnmatched;
algorithm
  outUnmatched:=
  matchcontinue (U,ass1,inUnmatched)
    local
      list<Integer> rest;
      Integer c;
    case ({},_,_) then inUnmatched;
    case (c::rest,_,_)
      equation
        true = intGt(ass1[c],0);
      then
        HKgetUnmatched(rest,ass1,inUnmatched);
    case (c::rest,_,_)
      then
        HKgetUnmatched(rest,ass1,c::inUnmatched);
  end matchcontinue;
end HKgetUnmatched;

protected function HKBFS
"function helper for HK, traverses all colums and perform a BFSB phase on each to get the level information
 the BFS stops at a colum with unmatched rows
 author: Frenkel TUD 2012-03"
  input list<Integer> colums;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input Integer i;
  input array<Integer> level;
  input Option<Integer> lowestL "lowest level find unmatched rows";
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input list<tuple<Integer,Integer>> inRows "(row,level)";
  output list<tuple<Integer,Integer>> outRows "unmatched rows found by BFS";
algorithm
  outRows:=
  match (colums,nv,ne,m,mT,rowmarks,i,level,lowestL,ass1,ass2,inRows)
    local
      list<Integer> rest;
      list<tuple<Integer,Integer>> rows;
      Integer c;
      Option<Integer> ll;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then inRows;
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        (rows,ll) = HKBFSBphase({c},i,0,lowestL,nv,ne,m,mT,rowmarks,level,ass1,ass2,inRows,{});
      then
        HKBFS(rest,nv,ne,m,mT,rowmarks,i,level,ll,ass1,ass2,rows);
    else
      equation
        Error.addInternalError("function HKBFS failed in phase " + intString(i), sourceInfo());
      then
        fail();
  end match;
end HKBFS;

protected function HKBFSBphase
"function helper for HKBFS, traverses all colums and perform a BFSB phase on each
 author: Frenkel TUD 2012-03"
  input list<Integer> queue;
  input Integer i;
  input Integer l "current level";
  input Option<Integer> lowestL "lowest level find unmatched rows";
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<tuple<Integer,Integer>> inRows;
  input list<Integer> queue1;
  output list<tuple<Integer,Integer>> outRows;
  output Option<Integer> outlowestL;
algorithm
  (outRows,outlowestL) :=
  match (queue,i,l,lowestL,nv,ne,m,mT,rowmarks,level,ass1,ass2,inRows,queue1)
    local
      list<Integer> rest,queue2,cr;
      list<tuple<Integer,Integer>> rows;
      Integer c,lowl,l_1;
      Boolean b;
      Option<Integer> ll;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,{}) then (inRows,lowestL);
    case ({},_,_,SOME(lowl),_,_,_,_,_,_,_,_,_,_)
      equation
        l_1 = l+1;
        b = intGt(l_1,lowl);
        (rows,ll) = HKBFSBphase1(b,queue1,i,l_1,lowestL,nv,ne,m,mT,rowmarks,level,ass1,ass2,inRows,{});
      then
        (rows,ll);
    case ({},_,_,NONE(),_,_,_,_,_,_,_,_,_,_)
      equation
        (rows,ll) = HKBFSBphase(queue1,i,l+1,lowestL,nv,ne,m,mT,rowmarks,level,ass1,ass2,inRows,{});
      then
        (rows,ll);
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        cr = List.select(m[c], Util.intPositive);
        arrayUpdate(level,c,l);
        (queue2,rows,b) = HKBFStraverseRows(cr,{},i,l,m,mT,rowmarks,level,ass1,ass2,inRows,false);
        queue2 = listAppend(queue1,queue2);
        ll = if b then SOME(l) else lowestL;
        (rows,ll) = HKBFSBphase(rest,i,l,ll,nv,ne,m,mT,rowmarks,level,ass1,ass2,rows,queue2);
      then
        (rows,ll);
    else
      equation
        Error.addInternalError("function HKBFSBphase failed in phase " + intString(i), sourceInfo());
      then
        fail();

  end match;
end HKBFSBphase;

protected function HKBFSBphase1
"function helper for HKBFSB
 author: Frenkel TUD 2012-03"
  input Boolean inUnMaRowFound;
  input list<Integer> queue;
  input Integer i;
  input Integer l;
  input Option<Integer> lowestL;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<tuple<Integer,Integer>> inRows;
  input list<Integer> queue1;
  output list<tuple<Integer,Integer>> outRows;
  output Option<Integer> outlowestL;
algorithm
  (outRows,outlowestL) :=
  match (inUnMaRowFound,queue,i,l,lowestL,nv,ne,m,mT,rowmarks,level,ass1,ass2,inRows,queue1)
    local
      Option<Integer> ll;
      list<tuple<Integer,Integer>> rows;
    case (true,_,_,_,_,_,_,_,_,_,_,_,_,_,_) then (inRows,SOME(l));
    case (false,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        (rows,ll) = HKBFSBphase(queue,i,l,lowestL,nv,ne,m,mT,rowmarks,level,ass1,ass2,inRows,queue1);
      then
        (rows,ll);
    else
      equation
        Error.addInternalError("function HKBFSBphase1 failed", sourceInfo());
      then
        fail();
  end match;
end HKBFSBphase1;

protected function HKBFStraverseRows
"function helper for BFSB, traverses all rows of a collum and set level
 author: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input list<Integer> queue;
  input Integer i;
  input Integer l;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<tuple<Integer,Integer>> inRows;
  input Boolean inunmarowFound;
  output list<Integer> outEqnqueue;
  output list<tuple<Integer,Integer>> outRows;
  output Boolean unmarowFound;
algorithm
  (outEqnqueue,outRows,unmarowFound):=
  matchcontinue (rows,queue,i,l,m,mT,rowmarks,level,ass1,ass2,inRows,inunmarowFound)
    local
      list<Integer> rest,queue1;
      list<tuple<Integer,Integer>> rowstpl;
      Integer rc,r;
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then (listReverse(queue),inRows,inunmarowFound);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is visited
        false = intLt(rowmarks[r],i);
        (queue1,rowstpl,b) = HKBFStraverseRows(rest,queue,i,l,m,mT,rowmarks,level,ass1,ass2,inRows,inunmarowFound);
      then
        (queue1,rowstpl,b);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is unmatched
        true = intLt(ass2[r],0);
        arrayUpdate(rowmarks,r,i);
        (queue1,rowstpl,b) = HKBFStraverseRows(rest,queue,i,l,m,mT,rowmarks,level,ass1,ass2,(r,l)::inRows,true);
      then
        (queue1,rowstpl,b);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is matched
        rc = ass2[r];
        false = intLt(rc,0);
        arrayUpdate(rowmarks,r,i);
        (queue1,rowstpl,b) = HKBFStraverseRows(rest,rc::queue,i,l,m,mT,rowmarks,level,ass1,ass2,inRows,inunmarowFound);
      then
        (queue1,rowstpl,b);
    else
      equation
        Error.addInternalError("function HKBFStraverseRows failed in phase " + intString(i), sourceInfo());
      then
        fail();

  end matchcontinue;
end HKBFStraverseRows;

protected function HKDFS
"function helper for HKDFSB, traverses all colums and perform a DFSB phase on each
 author: Frenkel TUD 2012-03"
  input list<tuple<Integer,Integer>> unmatchedRows;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> collummarks;
  input array<Integer> level;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input list<Integer> inUnmatchedRows;
  output list<Integer> outUnmatchedRows;
algorithm
  outUnmatchedRows:=
  match (unmatchedRows,i,nv,ne,m,mT,collummarks,level,ass1,ass2,inUnmatchedRows)
    local
       list<tuple<Integer,Integer>> rest;
       list<Integer> ur;
       Integer r,l;
       Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_) then inUnmatchedRows;
    case ((r,l)::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // search augmenting paths
        b = HKDFSphase({r},i,r,l,nv,ne,m,mT,collummarks,level,ass1,ass2,false);
        ur = List.consOnTrue(not b,r,inUnmatchedRows);
      then
        HKDFS(rest,i,nv,ne,m,mT,collummarks,level,ass1,ass2,ur);
    else
      equation
        Error.addInternalError("function HKDFS failed in phase " + intString(i), sourceInfo());
      then
        fail();

  end match;
end HKDFS;

protected function HKDFSphase
"function helper for HKDFSBphase, traverses all colums and perform a DFSB phase on each
 author: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer i;
  input Integer r;
  input Integer l;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> collummarks;
  input array<Integer> level;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input Boolean inMatched;
  output Boolean matched;
algorithm
  matched :=
  match (stack,i,r,l,nv,ne,m,mT,collummarks,level,ass1,ass2,inMatched)
    local
      list<Integer> collums;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_) then inMatched;
    case (_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        collums = List.select(mT[r], Util.intPositive);
      then
        HKDFStraverseCollums(collums,stack,i,l,nv,ne,m,mT,collummarks,level,ass1,ass2,inMatched);
    else
      equation
        Error.addInternalError("function HKDFSphase failed in phase " + intString(i), sourceInfo());
      then
        fail();
  end match;
end HKDFSphase;

protected function HKDFStraverseCollums
"function helper for HKDFSB, traverses all collums of a row and search a augmenting path
 author: Frenkel TUD 2012-03"
  input list<Integer> collums;
  input list<Integer> stack;
  input Integer i;
  input Integer l;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> collummarks;
  input array<Integer> level;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input Boolean inMatched;
  output Boolean matched;
algorithm
  matched:=
  matchcontinue (collums,stack,i,l,nv,ne,m,mT,collummarks,level,ass1,ass2,inMatched)
    local
      list<Integer> rest;
      Integer r,c;
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_) then inMatched;
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is not in graph
        false = intEq(level[c],l);
      then
        HKDFStraverseCollums(rest,stack,i,l,nv,ne,m,mT,collummarks,level,ass1,ass2,inMatched);
    case (c::_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is in graph
        true = intEq(level[c],l);
        // collum is unvisited
        true = intLt(collummarks[c],i);
        // collum is unmatched
        true = intLt(ass1[c],0);
        HKDFSreasign(stack,c,ass1,ass2);
      then
        true;
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is in graph
        true = intEq(level[c],l);
        // collum is unvisited
        true = intLt(collummarks[c],i);
        // collum is matched
        r = ass1[c];
        false = intLt(r,0);
        arrayUpdate(collummarks,c,i);
        b = HKDFSphase(r::stack,i,r,l-1,nv,ne,m,mT,collummarks,level,ass1,ass2,inMatched);
      then
        HKDFStraverseCollums1(b,rest,stack,i,l,nv,ne,m,mT,collummarks,level,ass1,ass2);
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is in graph
        true = intEq(level[c],l);
        // collum is visited
        false = intLt(collummarks[c],i);
      then
        HKDFStraverseCollums(rest,stack,i,l,nv,ne,m,mT,collummarks,level,ass1,ass2,inMatched);
    else
      equation
        Error.addInternalError("function HKDFStraverseCollums failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end HKDFStraverseCollums;

protected function HKDFStraverseCollums1
"function helper for HKDFSBtraverseCollums
 author: Frenkel TUD 2012-03"
  input Boolean inMatched;
  input list<Integer> rows;
  input list<Integer> stack;
  input Integer i;
  input Integer l;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> collummarks;
  input array<Integer> level;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output Boolean matched;
algorithm
  matched:=
  match (inMatched,rows,stack,i,l,nv,ne,m,mT,collummarks,level,ass1,ass2)
    case (true,_,_,_,_,_,_,_,_,_,_,_,_) then inMatched;
    else HKDFStraverseCollums(rows,stack,i,l,nv,ne,m,mT,collummarks,level,ass1,ass2,inMatched);
  end match;
end HKDFStraverseCollums1;

protected function HKDFSreasign
"function helper for HKDFS, reasignment(rematching) allong the augmenting path
 remove all edges from the assignments that are in the path
 add all other edges to the assignment
 author: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer c;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
algorithm
  _ := match (stack,c,ass1,ass2)
    local
      Integer r,cr;
      list<Integer> rest;
    case ({},_,_,_) then ();
    case (r::rest,_,_,_)
      equation
        cr = ass2[r];
        arrayUpdate(ass1,c,r);
        arrayUpdate(ass2,r,c);
        HKDFSreasign(rest,cr,ass1,ass2);
      then ();
   end match;
end HKDFSreasign;


public function HKDW
"        complexity O(sqrt(n)*tau)
 author: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> rowmarks,level,collummarks;
      list<Integer> unmatched;
    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        rowmarks = arrayCreate(nvars,-1);
        collummarks = arrayCreate(neqns,-1);
        level = arrayCreate(neqns,-1);
        unmatched = cheapmatchingalgorithm(nvars,neqns,m,mt,vec1,vec2,true);
        (vec1,vec2,syst,shared,arg) = HKDW1(0,unmatched,rowmarks,collummarks,level,isyst,ishared,nvars,neqns,vec1,vec2,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.HKDW failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end HKDW;

protected function HKDW1
"function: HKDW1, helper for HKDW
  author: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> unmatched;
  input array<Integer> rowmarks;
  input array<Integer> collummarks;
  input array<Integer> level;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  match (i,unmatched,rowmarks,collummarks,level,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt;
      Integer nv_1,ne_1,i_1;
      list<Integer> unmatched1;
      list<list<Integer>> meqns;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2,rowmarks1,collummarks1,level1;
    case (_,{},_,_,_,_,_,_,_,_,_,_,_,_)
      then
        (ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_)
      equation
        (i_1,unmatched1) = HKDWphase(i,unmatched,nv,ne,m,mt,rowmarks,collummarks,level,ass1,ass2,listLength(unmatched),{});
        meqns = getEqnsforIndexReduction(unmatched1,ne,m,mt,ass1,ass2,inArg);
        (unmatched1,rowmarks1,collummarks1,level1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg) = HK2(meqns,unmatched1,{},rowmarks,collummarks,level,syst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        (ass1_2,ass2_2,syst,shared,arg1) = HKDW1(i_1+1,unmatched1,rowmarks1,collummarks1,level1,syst,shared,nv_1,ne_1,ass1_1,ass2_1,inMatchingOptions,sssHandler,arg);
      then
        (ass1_2,ass2_2,syst,shared,arg1);
  end match;
end HKDW1;

protected function HKDWphase
"function helper for HKDW, traverses all unmatched
 colums and run a BFS and DFS
 author: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> U;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> collummarks;
  input array<Integer> level;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input Integer previousUnmatched;
  input list<Integer> unMatched;
  output Integer outI;
  output list<Integer> outunMatched;
algorithm
  (outI,outunMatched):=
  matchcontinue (i,U,nv,ne,m,mT,rowmarks,collummarks,level,ass1,ass2,previousUnmatched,unMatched)
    local
      list<Integer> unmatched;
      list<tuple<Integer,Integer>> rows;
      list<Integer> ur;
      Integer i_1;
    case (_,{},_,_,_,_,_,_,_,_,_,_,_)
      equation
        // no augmenting path is found in phase
        true=intEq(previousUnmatched,listLength(unMatched));
      then
        (i,unMatched);
    case (_,{},_,_,_,_,_,_,_,_,_,_,_)
      equation
       // augmenting path is found in phase, next round
        (i_1,unmatched) = HKphase(i+1,unMatched,nv,ne,m,mT,rowmarks,collummarks,level,ass1,ass2,listLength(unMatched),{});
      then
        (i_1,unmatched);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // BFS phase to get the level information
        rows = HKBFS(U,nv,ne,m,mT,rowmarks,i,level,NONE(),ass1,ass2,{});
        // DFS to match
        ur = HKDFS(rows,i,nv,ne,m,mT,collummarks,level,ass1,ass2,{});
        // second DFS in full graph
        HKDWDFS(ur,i,nv,ne,m,mT,collummarks,ass1,ass2);
        // remove matched collums from U
        unmatched = HKgetUnmatched(U,ass1,{});
        (i_1,unmatched) = HKphase(i,{},nv,ne,m,mT,rowmarks,collummarks,level,ass1,ass2,previousUnmatched,unmatched);
      then
        (i_1,unmatched);
    else
      equation
        Error.addInternalError("function HKDWphase failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end HKDWphase;

protected function HKDWDFS
"function helper for HKDWDFSB, traverses all colums and perform a DFSB phase on each
 author: Frenkel TUD 2012-03"
  input list<Integer> unmatchedRows;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> collummarks;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
algorithm
  _:=
  match (unmatchedRows,i,nv,ne,m,mT,collummarks,ass1,ass2)
    local
       list<Integer> rest;
       Integer r;
    case ({},_,_,_,_,_,_,_,_) then ();
    case (r::rest,_,_,_,_,_,_,_,_)
      equation
        // search augmenting paths
        _ = HKDWDFSphase({r},i,r,nv,ne,m,mT,collummarks,ass1,ass2,false);
        HKDWDFS(rest,i,nv,ne,m,mT,collummarks,ass1,ass2);
      then
        ();
    else
      equation
        Error.addInternalError("function HKDWDFS failed in phase " + intString(i), sourceInfo());
      then
        fail();

  end match;
end HKDWDFS;

protected function HKDWDFSphase
"function helper for HKDWDFSBphase, traverses all colums and perform a DFSB phase on each
 author: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer i;
  input Integer r;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> collummarks;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input Boolean inMatched;
  output Boolean matched;
algorithm
  matched :=
  match (stack,i,r,nv,ne,m,mT,collummarks,ass1,ass2,inMatched)
    local
      list<Integer> collums;
    case ({},_,_,_,_,_,_,_,_,_,_) then inMatched;
    case (_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        collums = List.select(mT[r], Util.intPositive);
      then
        HKDWDFStraverseCollums(collums,stack,i,nv,ne,m,mT,collummarks,ass1,ass2,inMatched);
    else
      equation
        Error.addInternalError("function HKDWDFSphase failed in phase " + intString(i), sourceInfo());
      then
        fail();
  end match;
end HKDWDFSphase;

protected function HKDWDFStraverseCollums
"function helper for HKDWDFSB, traverses all collums of a row and search a augmenting path
 author: Frenkel TUD 2012-03"
  input list<Integer> collums;
  input list<Integer> stack;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> collummarks;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input Boolean inMatched;
  output Boolean matched;
algorithm
  matched:=
  matchcontinue (collums,stack,i,nv,ne,m,mT,collummarks,ass1,ass2,inMatched)
    local
      list<Integer> rest;
      Integer r,c;
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_) then inMatched;
    case (c::_,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is unvisited
        true = intLt(collummarks[c],i);
        // collum is unmatched
        true = intLt(ass1[c],0);
        HKDFSreasign(stack,c,ass1,ass2);
      then
        true;
    case (c::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is unvisited
        true = intLt(collummarks[c],i);
        // collum is matched
        r = ass1[c];
        false = intLt(r,0);
        arrayUpdate(collummarks,c,i);
        b = HKDWDFSphase(r::stack,i,r,nv,ne,m,mT,collummarks,ass1,ass2,inMatched);
      then
        HKDWDFStraverseCollums1(b,rest,stack,i,nv,ne,m,mT,collummarks,ass1,ass2);
    case (c::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is visited
        false = intLt(collummarks[c],i);
      then
        HKDWDFStraverseCollums(rest,stack,i,nv,ne,m,mT,collummarks,ass1,ass2,inMatched);
    else
      equation
        Error.addInternalError("function HKDWDFStraverseCollums failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end HKDWDFStraverseCollums;

protected function HKDWDFStraverseCollums1
"function helper for HKDWDFSBtraverseCollums
 author: Frenkel TUD 2012-03"
  input Boolean inMatched;
  input list<Integer> rows;
  input list<Integer> stack;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> collummarks;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output Boolean matched;
algorithm
  matched:=
  match (inMatched,rows,stack,i,nv,ne,m,mT,collummarks,ass1,ass2)
    case (true,_,_,_,_,_,_,_,_,_,_) then inMatched;
    else HKDWDFStraverseCollums(rows,stack,i,nv,ne,m,mT,collummarks,ass1,ass2,inMatched);
  end match;
end HKDWDFStraverseCollums1;


public function ABMP
"        complexity O(sqrt(n)*tau)
 author: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> rowmarks,level,collummarks,rlevel,colptrs;
      list<Integer> unmatched;
    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        rowmarks = arrayCreate(nvars,-1);
        collummarks = arrayCreate(neqns,-1);
        level = arrayCreate(neqns,-1);
        rlevel = arrayCreate(nvars,nvars);
        colptrs = arrayCreate(neqns,-1);
        unmatched = cheapmatchingalgorithm(nvars,neqns,m,mt,vec1,vec2,true);
        (vec1,vec2,syst,shared,arg) = ABMP1(1,unmatched,rowmarks,collummarks,level,rlevel,colptrs,isyst,ishared,nvars,neqns,vec1,vec2,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.ABMP failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end ABMP;

protected function ABMP1
"function: ABMP1, helper for HKABMP
  author: Frenkel TUD 2012-03"
  input Integer i;
  input list<Integer> unmatched;
  input array<Integer> rowmarks;
  input array<Integer> collummarks;
  input array<Integer> level;
  input array<Integer> rlevel;
  input array<Integer> colptrs;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  match (i,unmatched,rowmarks,collummarks,level,rlevel,colptrs,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt;
      Integer nv_1,ne_1,i_1,lim;
      list<Integer> unmatched1;
      list<list<Integer>> meqns;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2,rowmarks1,collummarks1,level1,rlevel1;
    case (_,{},_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        (ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,_,_,BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_)
      equation
        lim = integer(0.1 * sqrt(arrayLength(ass1)));
        unmatched1 = ABMPphase(unmatched,i,nv,ne,m,mt,rowmarks,rlevel,colptrs,lim,ass1,ass2);
        (i_1,unmatched1) = HKphase(i+1,unmatched,nv,ne,m,mt,rowmarks,collummarks,level,ass1,ass2,listLength(unmatched),{});
        meqns = getEqnsforIndexReduction(unmatched1,ne,m,mt,ass1,ass2,inArg);
        (unmatched1,rowmarks1,collummarks1,level1,rlevel1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg) = ABMP2(meqns,unmatched1,{},rowmarks,collummarks,level,rlevel,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        (ass1_2,ass2_2,syst,shared,arg1) = ABMP1(i_1+1,unmatched1,rowmarks1,collummarks1,level1,rlevel1,colptrs,syst,shared,nv_1,ne_1,ass1_1,ass2_1,inMatchingOptions,sssHandler,arg);
      then
        (ass1_2,ass2_2,syst,shared,arg1);
  end match;
end ABMP1;

protected function ABMP2
"function: ABMP2, helper for ABMP
  author: Frenkel TUD 2012-03"
  input list<list<Integer>> meqns "Marked Equations for Index Reduction";
  input list<Integer> unmatched;
  input list<Integer> changedEqns;
  input array<Integer> rowmarks;
  input array<Integer> collummarks;
  input array<Integer> level;
  input array<Integer> rlevel;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output list<Integer> outunmatched;
  output array<Integer> outrowmarks;
  output array<Integer> outcollummarks;
  output array<Integer> outlevel;
  output array<Integer> outrlevel;
  output Integer nvars;
  output Integer neqns;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outunmatched,outrowmarks,outcollummarks,outlevel,outrlevel,nvars,neqns,outAss1,outAss2,osyst,oshared,outArg):=
  match (meqns,unmatched,changedEqns,rowmarks,collummarks,level,rlevel,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      Integer nv_1,ne_1;
      list<Integer> unmatched1;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> ass1_1,ass2_1,rowmarks1,collummarks1,level1,rlevel1;

    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        (unmatched,rowmarks,collummarks,level,rlevel,nv,ne,ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,(BackendDAE.INDEX_REDUCTION(),_),_,_)
      equation
        (unmatched1,_,syst,shared,ass2_1,ass1_1,arg) = sssHandler(meqns,0,isyst,ishared,ass2,ass1,inArg);
        ne_1 = BackendDAEUtil.systemSize(syst);
        nv_1 = BackendVariable.daenumVariables(syst);
        ass1_1 = assignmentsArrayExpand(ass1_1,ne_1,arrayLength(ass1_1),-1);
        ass2_1 = assignmentsArrayExpand(ass2_1,nv_1,arrayLength(ass2_1),-1);
        rowmarks1 = assignmentsArrayExpand(rowmarks,nv_1,arrayLength(rowmarks),-1);
        collummarks1 = assignmentsArrayExpand(collummarks,ne_1,arrayLength(collummarks),-1);
        rlevel1 = arrayCreate(arrayLength(ass2_1),arrayLength(ass2_1));
        level1 = assignmentsArrayExpand(level,ne_1,arrayLength(level),-1);
      then
        (unmatched1,rowmarks1,collummarks1,level1,rlevel1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        singularSystemError(meqns,0,isyst,ishared,ass2,ass1,inArg);
      then
        fail();
  end match;
end ABMP2;

protected function ABMPphase
"function helper for ABMP, traverses all unmatched
 colums and run a BFS and DFS to assign level information
 and increase matching.
 author: Frenkel TUD 2012-03"
  input list<Integer> U;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> colptrs;
  input Integer lim;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  output list<Integer> unMatched;
algorithm
  unMatched:=
  match (U,i,nv,ne,m,mT,rowmarks,level,colptrs,lim,ass1,ass2)
    local
      list<Integer> ur;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then {};
    case (_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // BFS to assign levels
        ur = ABMPBFSphase(U,i,0,lim,listLength(U),nv,ne,m,mT,rowmarks,level,ass1,ass2,{},{});
      then
        ABMPphase1(U,ur,i,nv,ne,m,mT,rowmarks,level,colptrs,lim,ass1,ass2);
    else
      equation
        Error.addInternalError("function ABMPphase failed", sourceInfo());
      then
        fail();
  end match;
end ABMPphase;

protected function ABMPphase1
"function helper for ABMP, traverses all unmatched
 colums and run a BFS and DFS to assign level information
 and increase matching.
 author: Frenkel TUD 2012-03"
  input list<Integer> U;
  input list<Integer> unmatchedRows;
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> colptrs;
  input Integer lim;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  output list<Integer> unMatched;
algorithm
  unMatched:=
  match (U,unmatchedRows,i,nv,ne,m,mT,rowmarks,level,colptrs,lim,ass1,ass2)
    local
      list<Integer> unmatched;
      Integer L,r;
    case (_,{},_,_,_,_,_,_,_,_,_,_,_) then U;
    case (_,r::_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        L = level[r];
        ABMPDFS(unmatchedRows,0,L,nv,ne,m,mT,level,colptrs,ass1,ass2,{});
        // remove unmatched collums from U
        unmatched = HKgetUnmatched(U,ass1,{});
      then
        ABMPphase2(unmatched,i,L,nv,ne,m,mT,rowmarks,level,colptrs,lim,ass1,ass2);
    else
      equation
        Error.addInternalError("function ABMPphase1 failed", sourceInfo());
      then
        fail();
  end match;
end ABMPphase1;

protected function ABMPphase2
"function helper for ABMP, traverses all unmatched
 colums and run a BFS and DFS to assign level information
 and increase matching.
 author: Frenkel TUD 2012-03"
  input list<Integer> U;
  input Integer i;
  input Integer L;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> colptrs;
  input Integer lim;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  output list<Integer> unMatched;
algorithm
  unMatched:=
  matchcontinue (U,i,L,nv,ne,m,mT,rowmarks,level,colptrs,lim,ass1,ass2)
    case ({},_,_,_,_,_,_,_,_,_,_,_,_) then U;
    case (_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(50*L,listLength(U));
      then
       U;
    case (_,_,_,_,_,_,_,_,_,_,_,_,_)
      // next round width updated level
      then
       ABMPphase(U,i,nv,ne,m,mT,rowmarks,level,colptrs,lim,ass1,ass2);
    else
      equation
        Error.addInternalError("function ABMPphase2 failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end ABMPphase2;

protected function ABMPBFSphase
"function helper for ABMP, traverses all colums and set level information
 author: Frenkel TUD 2012-03"
  input list<Integer> queue;
  input Integer i;
  input Integer L;
  input Integer lim;
  input Integer lim1;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> nextqueue;
  input list<Integer> unMatched;
  output list<Integer> outunMatched;
algorithm
  outunMatched :=
  match (queue,i,L,lim,lim1,nv,ne,m,mT,rowmarks,level,ass1,ass2,nextqueue,unMatched)
    local
      list<Integer> rest,rows,queue1,unmatched;
      Integer c,l;
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,{},_) then unMatched;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        l = L+2;
        b = intGt(l,lim) or intGt(50*l,lim1);
      then
        ABMPBFSphase1(b,nextqueue,i,l,lim,lim1,nv,ne,m,mT,rowmarks,level,ass1,ass2,{},unMatched);
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        rows = List.select(m[c], Util.intPositive);
        (queue1,unmatched) = ABMPBFStraverseRows(rows,i,L,nv,ne,m,mT,rowmarks,level,ass1,ass2,nextqueue,unMatched);
      then
        ABMPBFSphase(rest,i,L,lim,lim1,nv,ne,m,mT,rowmarks,level,ass1,ass2,queue1,unmatched);
    else
      equation
        Error.addInternalError("function ABMPBFSphase failed", sourceInfo());
      then
        fail();
  end match;
end ABMPBFSphase;

protected function ABMPBFSphase1
"function helper for ABMPBFSphase
 author: Frenkel TUD 2012-03"
  input Boolean inStop;
  input list<Integer> queue;
  input Integer i;
  input Integer L;
  input Integer lim;
  input Integer lim1;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> nextqueue;
  input list<Integer> unMatched;
  output list<Integer> outunMatched;
algorithm
  outunMatched :=
  match (inStop,queue,i,L,lim,lim1,nv,ne,m,mT,rowmarks,level,ass1,ass2,nextqueue,unMatched)
    case (true,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_) then unMatched;
    case (false,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        ABMPBFSphase(queue,i,L,lim,lim1,nv,ne,m,mT,rowmarks,level,ass1,ass2,nextqueue,unMatched);
    else
      equation
        Error.addInternalError("function ABMPBFSphase1 failed", sourceInfo());
      then
        fail();
  end match;
end ABMPBFSphase1;

protected function ABMPBFStraverseRows
"function helper for ABMPBFS, traverses all rows and assign level informaiton
 author: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input Integer i;
  input Integer L;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> rowmarks;
  input array<Integer> level;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> queue;
  input list<Integer> unMatched;
  output list<Integer> outEqnqueue;
  output list<Integer> outUnmatched;
algorithm
  (outEqnqueue,outUnmatched):=
  matchcontinue (rows,i,L,nv,ne,m,mT,rowmarks,level,ass1,ass2,queue,unMatched)
    local
      list<Integer> rest,queue1,unmatched;
      Integer rc,r;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_) then (listReverse(queue),unMatched);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is unvisited
        false = intEq(rowmarks[r],i);
        // row is unmatched
        true = intLt(ass2[r],0);
        arrayUpdate(level,r,L);
        arrayUpdate(rowmarks,r,i);
        (queue1,unmatched) = ABMPBFStraverseRows(rest,i,L,nv,ne,m,mT,rowmarks,level,ass1,ass2,queue,r::unMatched);
      then
        (queue1,unmatched);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is unvisited
        false = intEq(rowmarks[r],i);
        // row is matched
        rc = ass2[r];
        false = intLt(rc,0);
        arrayUpdate(rowmarks,r,i);
        (queue1,unmatched) = ABMPBFStraverseRows(rest,i,L,nv,ne,m,mT,rowmarks,level,ass1,ass2,rc::queue,unMatched);
      then
        (queue1,unmatched);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is visited
        true = intEq(rowmarks[r],i);
        (queue1,unmatched) = ABMPBFStraverseRows(rest,i,L,nv,ne,m,mT,rowmarks,level,ass1,ass2,queue,unMatched);
      then
        (queue1,unmatched);
    else
      equation
        Error.addInternalError("function ABMPBFStraverseRows failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end ABMPBFStraverseRows;

protected function ABMPDFS
"function helper for ABMPDFS, traverses all rows and perform a DFSB phase on each
 author: Frenkel TUD 2012-03"
  input list<Integer> unmatchedRows;
  input Integer i;
  input Integer L;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> level;
  input array<Integer> colptrs;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input list<Integer> unMatched;
algorithm
  _:=
  matchcontinue (unmatchedRows,i,L,nv,ne,m,mT,level,colptrs,ass1,ass2,unMatched)
    local
       list<Integer> rest,unmatched;
       Integer r,i_1;
       Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then ();
    case (_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        false = intLt(i,ne);
      then ();
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // search augmenting paths
        arrayUpdate(colptrs,r,0);
        (i_1,b) = ABMPDFSphase({r},i,r,nv,ne,m,mT,level,colptrs,ass1,ass2);
        unmatched = List.consOnTrue(not b, r, unMatched);
        ABMPDFS1(b,r,rest,unmatched,i_1,L,nv,ne,m,mT,level,colptrs,ass1,ass2);
      then
        ();
    else
      equation
        Error.addInternalError("function ABMPBFS failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end ABMPDFS;

protected function ABMPDFS1
"function helper for ABMPDFS, traverses all rows and perform a DFSB phase on each
 author: Frenkel TUD 2012-03"
  input Boolean inMatched;
  input Integer r;
  input list<Integer> unmatchedRows;
  input list<Integer> unMatched;
  input Integer i;
  input Integer L;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> level;
  input array<Integer> colptrs;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
algorithm
  _:=
  matchcontinue (inMatched,r,unmatchedRows,unMatched,i,L,nv,ne,m,mT,level,colptrs,ass1,ass2)
    local
       list<Integer> unmatched;
       Integer r1,r2,l;
    case (_,_,{},_,_,_,_,_,_,_,_,_,_,_) then ();
    case (true,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(50*L,listLength(unmatchedRows)+listLength(unMatched));
      then ();
    case (true,_,_,{},_,_,_,_,_,_,_,_,_,_)
      equation
        false = intGt(50*L,listLength(unmatchedRows)+listLength(unMatched));
        ABMPDFS(unmatchedRows,i,L,nv,ne,m,mT,level,colptrs,ass1,ass2,{});
      then ();
    case (true,_,r1::_,r2::{},_,_,_,_,_,_,_,_,_,_)
      equation
        false = intGt(50*L,listLength(unmatchedRows)+listLength(unMatched));
        false = intEq(L,level[r1]);
        l = level[r2];
        ABMPDFS(r2::unmatchedRows,i,l,nv,ne,m,mT,level,colptrs,ass1,ass2,{});
      then ();
    case (true,_,r1::_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        false = intGt(50*L,listLength(unmatchedRows)+listLength(unMatched));
        false = intEq(L,level[r1]);
        (r2::unmatched) = listReverse(unMatched);
        l = level[r2];
        unmatched = listAppend(unmatched,r2::unmatchedRows);
        ABMPDFS(unmatchedRows,i,l,nv,ne,m,mT,level,colptrs,ass1,ass2,{});
      then ();
    case (_,_,r1::_,{},_,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(L,level[r1]);
        l = level[r];
        ABMPDFS(unmatchedRows,i,l,nv,ne,m,mT,level,colptrs,ass1,ass2,{});
      then ();
    case (_,_,r1::_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        false = intEq(L,level[r1]);
        (r2::unmatched) = listReverse(unMatched);
        l = level[r2];
        unmatched = listAppend(r2::unmatched,unmatchedRows);
        ABMPDFS(unmatched,i,l,nv,ne,m,mT,level,colptrs,ass1,ass2,{});
      then ();
    case (_,_,r1::_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(L,level[r1]);
        ABMPDFS(unmatchedRows,i,L,nv,ne,m,mT,level,colptrs,ass1,ass2,unMatched);
      then ();
    else
      equation
        Error.addInternalError("function ABMPBFS1 failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end ABMPDFS1;

protected function ABMPDFSphase
"function helper for ABMPDFSBphase, traverses all colums and perform a DFSB phase on each
 author: Frenkel TUD 2012-03"
  input list<Integer> stack;
  input Integer i;
  input Integer r;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> level;
  input array<Integer> colptrs;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output Integer outI;
  output Boolean matched;
algorithm
  (outI,matched) :=
  match (stack,i,r,nv,ne,m,mT,level,colptrs,ass1,ass2)
    local
      list<Integer> collums;
      Integer desL,i_1;
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_) then (i,false);
    case (_,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        collums = List.select(mT[r], Util.intPositive);
        collums = List.stripN(collums,colptrs[r]);
        desL = level[r]-2;
        (i_1,b) = ABMPDFStraverseCollums(collums,1,stack,r,i,desL,nv,ne,m,mT,level,colptrs,ass1,ass2);
      then
        (i_1,b);
    else
      equation
        Error.addInternalError("function ABMPDFSphase failed in phase " + intString(i), sourceInfo());
      then
        fail();
  end match;
end ABMPDFSphase;

protected function ABMPDFStraverseCollums
"function helper for ABMPDFSB, traverses all collums of a row and search a augmenting path
 author: Frenkel TUD 2012-03"
  input list<Integer> collums;
  input Integer counter;
  input list<Integer> stack;
  input Integer r;
  input Integer i;
  input Integer desL;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> level;
  input array<Integer> colptrs;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output Integer outI;
  output Boolean matched;
algorithm
  (outI,matched):=
  matchcontinue (collums,counter,stack,r,i,desL,nv,ne,m,mT,level,colptrs,ass1,ass2)
    local
      list<Integer> rest;
      Integer rc,c,i_1;
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        arrayUpdate(level,r,level[r]+2);
        arrayUpdate(colptrs,r,0);
      then
        (i+1,false);
    case (c::_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is unmatched
        true = intLt(ass1[c],0);
        arrayUpdate(colptrs,r,counter);
        HKDFSreasign(stack,c,ass1,ass2);
      then
        (i,true);
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // collum is unvisited
        true = intEq(level[c],desL);
        // collum is matched
        rc = ass1[c];
        true = intGt(rc,0);
        arrayUpdate(colptrs,r,counter);
        (i_1,b) = ABMPDFSphase(rc::stack,i,rc,nv,ne,m,mT,level,colptrs,ass1,ass2);
        (i_1,b) = ABMPDFStraverseCollums1(b,counter+1,rest,stack,r,i_1,desL,nv,ne,m,mT,level,colptrs,ass1,ass2);
      then
        (i_1,b);
    case (_::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        (i_1,b) = ABMPDFStraverseCollums(rest,counter+1,stack,r,i,desL,nv,ne,m,mT,level,colptrs,ass1,ass2);
      then
        (i_1,b);
    else
      equation
        Error.addInternalError("function ABMPDFSBtraverseCollums failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end ABMPDFStraverseCollums;

protected function ABMPDFStraverseCollums1
"function helper for ABMPDFSBtraverseCollums
 author: Frenkel TUD 2012-03"
  input Boolean inMatched;
  input Integer counter;
  input list<Integer> rows;
  input list<Integer> stack;
  input Integer r;
  input Integer i;
  input Integer desL;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> level;
  input array<Integer> colptrs;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output Integer outI;
  output Boolean matched;
algorithm
 (outI,matched):=
  match (inMatched,counter,rows,stack,r,i,desL,nv,ne,m,mT,level,colptrs,ass1,ass2)
    local
      Integer i_1;
      Boolean b;
    case (true,_,_,_,_,i_1,_,_,_,_,_,_,_,_,_)
       then (i_1,true);
    else
      equation
        (i_1,b) = ABMPDFStraverseCollums(rows,counter,stack,r,i,desL,nv,ne,m,mT,level,colptrs,ass1,ass2);
      then
        (i_1,b);
  end match;
end ABMPDFStraverseCollums1;


public function PR_FIFO_FAIR
"        complexity O(n*tau)
 author: Frenkel TUD 2012-04"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> l_label,r_label;
      list<Integer> unmatched;

    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        l_label = arrayCreate(neqns,-1);
        r_label = arrayCreate(nvars,-1);
        unmatched = cheapmatchingalgorithm(nvars,neqns,m,mt,vec1,vec2,true);
        (vec1,vec2,syst,shared,arg) = PR_FIFO_FAIR1(unmatched,l_label,r_label,isyst,ishared,nvars,neqns,vec1,vec2,inMatchingOptions,sssHandler,inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.PR_FIFO_FAIR failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end PR_FIFO_FAIR;

protected function PR_FIFO_FAIR1
"function: PR_FIFO_FAIR1, helper for PR_FIFO_FAIR
  author: Frenkel TUD 2012-03"
  input list<Integer> unmatched;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  matchcontinue (unmatched,l_label,r_label,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt;
      Integer nv_1,ne_1;
      list<Integer> unmatched1;
      list<list<Integer>> meqns;
      String eqn_str,var_str;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      DAE.ElementSource source;
      SourceInfo info;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2,l_label1,r_label1;
      array<Integer> mapIncRowEqn;
    case ({},_,_,_,_,_,_,_,_,_,_,_)
      then
        (ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_)
      equation
        PR_Global_Relabel(l_label,r_label,nv,ne,m,mt,ass1,ass2);
        PR_FIFO_FAIRphase(0,unmatched,nv+ne,-1,nv,ne,m,mt,l_label,r_label,ass1,ass2,{});
        unmatched1 = getUnassigned(ne, ass1, {});
        meqns = getEqnsforIndexReduction(unmatched1,ne,m,mt,ass1,ass2,inArg);
        (unmatched1,l_label1,r_label1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg) = PR_FIFO_FAIR2(meqns,unmatched1,{},l_label,r_label,syst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
        (ass1_2,ass2_2,syst,shared,arg1) = PR_FIFO_FAIR1(unmatched1,l_label1,r_label1,syst,shared,nv_1,ne_1,ass1_1,ass2_1,inMatchingOptions,sssHandler,arg);
      then
        (ass1_2,ass2_2,syst,shared,arg1);
    case (_,_,_,_,_,_,_,_,_,_,_,(_,_,_,mapIncRowEqn,_))
      equation
        // get from scalar eqns indexes the indexes in the equation array
        unmatched1 = List.map1r(unmatched,arrayGet,mapIncRowEqn);
        unmatched1 = List.uniqueIntN(unmatched1,arrayLength(mapIncRowEqn));
        eqn_str = BackendDump.dumpMarkedEqns(isyst, unmatched1);
        unmatched1 = getUnassigned(nv, ass2, {});
        var_str = BackendDump.dumpMarkedVars(isyst, unmatched1);
        source = BackendEquation.markedEquationSource(isyst, listHead(unmatched1));
        info = DAEUtil.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.STRUCT_SINGULAR_SYSTEM, {eqn_str,var_str}, info);
      then
        fail();
  end matchcontinue;
end PR_FIFO_FAIR1;

protected function PR_FIFO_FAIR2
"function: PR_FIFO_FAIR2, helper for PR_FIFO_FAIR
  author: Frenkel TUD 2012-03"
  input list<list<Integer>> meqns "Marked Equations for Index Reduction";
  input list<Integer> unmatched;
  input list<Integer> changedEqns;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output list<Integer> outunmatched;
  output array<Integer> outl_label;
  output array<Integer> outr_label;
  output Integer nvars;
  output Integer neqns;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outunmatched,outl_label,outr_label,nvars,neqns,outAss1,outAss2,osyst,oshared,outArg):=
  match (meqns,unmatched,changedEqns,l_label,r_label,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      Integer nv_1,ne_1;
      list<Integer> unmatched1;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> ass1_1,ass2_1,l_label1,r_label1;

    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        (unmatched,l_label,r_label,nv,ne,ass1,ass2,isyst,ishared,inArg);
    case (_,_,_,_,_,_,_,_,_,_,_,(BackendDAE.INDEX_REDUCTION(),_),_,_)
      equation
        (unmatched1,_,syst,shared,ass2_1,ass1_1,arg) = sssHandler(meqns,0,isyst,ishared,ass2,ass1,inArg);
        ne_1 = BackendDAEUtil.systemSize(syst);
        nv_1 = BackendVariable.daenumVariables(syst);
        ass1_1 = assignmentsArrayExpand(ass1_1,ne_1,arrayLength(ass1_1),-1);
        ass2_1 = assignmentsArrayExpand(ass2_1,nv_1,arrayLength(ass2_1),-1);
        l_label1 = assignmentsArrayExpand(l_label,ne_1,arrayLength(l_label),-1);
        r_label1 = assignmentsArrayExpand(r_label,nv_1,arrayLength(r_label),-1);
      then
        (unmatched1,l_label1,r_label1,nv_1,ne_1,ass1_1,ass2_1,syst,shared,arg);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        singularSystemError(meqns,0,isyst,ishared,ass1,ass2,inArg);
      then
        fail();
  end match;
end PR_FIFO_FAIR2;

protected function PR_Global_Relabel
"function PR_Global_Relabel, helper for PR_FIFO_FAIR,
          update the labels of eatch vertex
 author: Frenkel TUD 2012-04"
  input array<Integer> l_label;
  input array<Integer> r_label;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
protected
  list<Integer> queue;
  Integer max;
algorithm
  max := nv+ne;
  PR_Global_Relabel_init_l_label(1,ne,max,l_label);
  queue := PR_Global_Relabel_init_r_label(1,nv,max,r_label,ass2,{});
  PR_Global_Relabel1(queue,l_label,r_label,max,nv,ne,m,mT,ass1,ass2,{});
end PR_Global_Relabel;

protected function PR_Global_Relabel_init_l_label
"function PR_Global_Relabel_init_l_label, helper for PR_Global_Relabel
 author: Frenkel TUD 2012-04"
  input Integer i;
  input Integer ne;
  input Integer max;
  input array<Integer> l_label;
algorithm
  _ := matchcontinue(i,ne,max,l_label)
    case(_,_,_,_)
      equation
        true = intGt(i,ne);
      then
        ();
    else
      equation
        arrayUpdate(l_label,i,max);
        PR_Global_Relabel_init_l_label(i+1,ne,max,l_label);
      then
        ();
  end matchcontinue;
end PR_Global_Relabel_init_l_label;

protected function PR_Global_Relabel_init_r_label
"function PR_Global_Relabel_init_r_label, helper for PR_Global_Relabel
 author: Frenkel TUD 2012-04"
  input Integer i;
  input Integer nv;
  input Integer max;
  input array<Integer> r_label;
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> inQueue;
  output list<Integer> outQueue;
algorithm
  outQueue := matchcontinue(i,nv,max,r_label,ass2,inQueue)
    case(_,_,_,_,_,_)
      equation
        true = intGt(i,nv);
      then
        listReverse(inQueue);
    case(_,_,_,_,_,_)
      equation
        false = intGt(i,nv);
        false = intGt(ass2[i],0);
        arrayUpdate(r_label,i,0);
      then
        PR_Global_Relabel_init_r_label(i+1,nv,max,r_label,ass2,i::inQueue);
    else
      equation
        arrayUpdate(r_label,i,max);
      then
        PR_Global_Relabel_init_r_label(i+1,nv,max,r_label,ass2,inQueue);
  end matchcontinue;
end PR_Global_Relabel_init_r_label;

protected function PR_Global_Relabel1
"function PR_Global_Relabel, helper for PR_FIFO_FAIR,
          update the labels of eatch vertex
 author: Frenkel TUD 2012-04"
  input list<Integer> queue;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input Integer max;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> nextqueue;
algorithm
  _ := matchcontinue(queue,l_label,r_label,max,nv,ne,m,mT,ass1,ass2,nextqueue)
    local
      list<Integer> rest,collums,queue1;
      Integer r;
    case({},_,_,_,_,_,_,_,_,_,{}) then ();
    case({},_,_,_,_,_,_,_,_,_,_)
      equation
        PR_Global_Relabel1(listReverse(nextqueue),l_label,r_label,max,nv,ne,m,mT,ass1,ass2,{});
      then
        ();
    case(r::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        collums = List.select(mT[r], Util.intPositive);
        queue1 = PR_Global_Relabel_traverseCollums(collums,max,r,l_label,r_label,nv,ne,m,mT,ass1,ass2,nextqueue);
        PR_Global_Relabel1(rest,l_label,r_label,max,nv,ne,m,mT,ass1,ass2,queue1);
      then
        ();
  end matchcontinue;
end PR_Global_Relabel1;

protected function PR_Global_Relabel_traverseCollums
"function helper for PR_Global_Relabel1, traverses all collums of a row and asing label indexes
 author: Frenkel TUD 2012-04"
  input list<Integer> collums;
  input Integer max;
  input Integer r;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> nextqueue;
  output list<Integer> outQueue;
algorithm
  outQueue:=
  matchcontinue (collums,max,r,l_label,r_label,nv,ne,m,mT,ass1,ass2,nextqueue)
    local
      list<Integer> rest;
      Integer rc,c;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then nextqueue;
    case (c::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(l_label[c],max);
        arrayUpdate(l_label,c,r_label[r]+1);
        rc = ass1[c];
        true = intGt(rc,-1);
        true = intEq(r_label[rc] ,max);
        arrayUpdate(r_label,rc,l_label[c]+1);
      then
        PR_Global_Relabel_traverseCollums(rest,max,r,l_label,r_label,nv,ne,m,mT,ass1,ass2,rc::nextqueue);
    case (_::rest,_,_,_,_,_,_,_,_,_,_,_)
      then
        PR_Global_Relabel_traverseCollums(rest,max,r,l_label,r_label,nv,ne,m,mT,ass1,ass2,nextqueue);
    else
      equation
        Error.addInternalError("function PR_Global_Relabel_traverseCollums failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end PR_Global_Relabel_traverseCollums;


protected function PR_FIFO_FAIRphase
"function PR_FIFO_FAIRphase, match rows and collums with push relabel tecnic
 author: Frenkel TUD 2012-04"
  input Integer relabels;
  input list<Integer> U;
  input Integer max;
  input Integer min_vertex;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> nextqueue;
algorithm
  _ := matchcontinue(relabels,U,max,min_vertex,nv,ne,m,mT,l_label,r_label,ass1,ass2,nextqueue)
    local
      list<Integer> rest,queue;
      Integer c,min_label,rlcount,minvertex;
    case(_,{},_,_,_,_,_,_,_,_,_,_,{}) then ();
    case(_,{},_,_,_,_,_,_,_,_,_,_,_)
      equation
        PR_FIFO_FAIRphase(relabels,nextqueue,max,min_vertex,nv,ne,m,mT,l_label,r_label,ass1,ass2,{});
      then ();
    case(_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(relabels,max);
        PR_Global_Relabel(l_label,r_label,nv,ne,m,mT,ass1,ass2);
        PR_FIFO_FAIRphase(0,U,max,min_vertex,nv,ne,m,mT,l_label,r_label,ass1,ass2,nextqueue);
      then ();
    case(_,c::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        (rlcount,min_label,minvertex) = PR_FIFO_FAIRphase1(intLt(l_label[c],max),relabels+1,c,min_vertex,max,max,nv,ne,m,mT,l_label,r_label,ass1,ass2);
        queue = PR_FIFO_FAIRrelabel(c,minvertex,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2,nextqueue);
        PR_FIFO_FAIRphase(rlcount,rest,max,minvertex,nv,ne,m,mT,l_label,r_label,ass1,ass2,queue);
      then ();
  end matchcontinue;
end PR_FIFO_FAIRphase;

protected function PR_FIFO_FAIRphase1
"function helper for PR_FIFO_FAIRphase
 author: Frenkel TUD 2012-04"
  input Boolean b;
  input Integer relabels;
  input Integer max_vertex;
  input Integer min_vertec;
  input Integer min_label;
  input Integer max;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output Integer outRelabels;
  output Integer outMinLabels;
  output Integer outMinVertex;
algorithm
  (outRelabels,outMinLabels,outMinVertex) :=
  match(b,relabels,max_vertex,min_vertec,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2)
    local
      Integer rel,minlab,minvert,tmp;
    case(true,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        tmp = intMod(l_label[max_vertex],4);
        (rel,minlab,minvert) = PR_FIFO_FAIRphase2(intEq(tmp,1),relabels,max_vertex,min_vertec,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2);
      then
        (rel,minlab,minvert);
    else
      then
       (relabels,min_label,min_vertec);
  end match;
end PR_FIFO_FAIRphase1;

protected function PR_FIFO_FAIRphase2
"function helper for PR_FIFO_FAIRphase
 author: Frenkel TUD 2012-04"
  input Boolean b;
  input Integer relabels;
  input Integer max_vertex;
  input Integer min_vertec;
  input Integer min_label;
  input Integer max;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output Integer outRelabels;
  output Integer outMinLabels;
  output Integer outMinVertex;
algorithm
  (outRelabels,outMinLabels,outMinVertex) :=
  match(b,relabels,max_vertex,min_vertec,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2)
    local
      list<Integer> rows;
      Integer rel,minlab,minvert;
    case(true,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        rows = List.select(m[max_vertex], Util.intPositive);
        (rel,minlab,minvert) = PR_FIFO_FAIRphase_traverseRows(rows,relabels,max_vertex,min_vertec,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2);
      then
        (rel,minlab,minvert);
    else
      equation
        rows = List.select(m[max_vertex], Util.intPositive);
        rows = listReverse(rows);
        (rel,minlab,minvert) = PR_FIFO_FAIRphase_traverseRows(rows,relabels,max_vertex,min_vertec,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2);
      then
       (rel,minlab,minvert);
  end match;
end PR_FIFO_FAIRphase2;

protected function PR_FIFO_FAIRphase_traverseRows
"function helper for PR_FIFO_FAIRphase2
 author: Frenkel TUD 2012-04"
  input list<Integer> rows;
  input Integer relabels;
  input Integer max_vertex;
  input Integer min_vertex;
  input Integer min_label;
  input Integer max;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output Integer outRelabels;
  output Integer outMinLabels;
  output Integer outMinVertex;
algorithm
  (outRelabels,outMinLabels,outMinVertex) :=
  matchcontinue(rows,relabels,max_vertex,min_vertex,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2)
    local
      list<Integer> rest;
      Integer r,minlabel,minvertex,rel;
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_) then (relabels,min_label,min_vertex);
    case (r::_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intLt(r_label[r],min_label);
        minlabel = r_label[r];
        minvertex = r;
        true = intEq(r_label[minvertex],l_label[max_vertex]-1);
      then
        (relabels-1,minlabel,minvertex);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intLt(r_label[r],min_label);
        minlabel = r_label[r];
        minvertex = r;
        false = intEq(r_label[minvertex],l_label[max_vertex]-1);
        (rel,minlabel,minvertex) = PR_FIFO_FAIRphase_traverseRows(rest,relabels,max_vertex,minvertex,minlabel,max,nv,ne,m,mT,l_label,r_label,ass1,ass2);
      then
        (rel,minlabel,minvertex);
    case (_::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        (rel,minlabel,minvertex) = PR_FIFO_FAIRphase_traverseRows(rest,relabels,max_vertex,min_vertex,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2);
      then
        (rel,minlabel,minvertex);
    else
      equation
        Error.addInternalError("function PR_FIFO_FAIRphase_traverseRows failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end PR_FIFO_FAIRphase_traverseRows;

protected function PR_FIFO_FAIRrelabel
"function helper for PR_FIFO_FAIRphase
 author: Frenkel TUD 2012-04"
  input Integer max_vertex;
  input Integer min_vertex;
  input Integer min_label;
  input Integer max;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> l_label;
  input array<Integer> r_label;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> inQueue;
  output list<Integer> outQueue;
algorithm
  outQueue := matchcontinue (max_vertex,min_vertex,min_label,max,nv,ne,m,mT,l_label,r_label,ass1,ass2,inQueue)
    local
      Integer next_vertex;
    case(_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intLt(min_label,max);
        true = intLt(ass2[min_vertex],0);
        arrayUpdate(ass2,min_vertex,max_vertex);
        arrayUpdate(ass1,max_vertex,min_vertex);
        arrayUpdate(r_label,min_vertex,min_label+2);
      then
        inQueue;
    case(_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intLt(min_label,max);
        false = intLt(ass2[min_vertex],0);
        next_vertex = ass2[min_vertex];
        arrayUpdate(ass2,min_vertex,max_vertex);
        arrayUpdate(ass1,max_vertex,min_vertex);
        arrayUpdate(ass1,next_vertex,-1);
        arrayUpdate(l_label,max_vertex,min_label+1);
        arrayUpdate(r_label,min_vertex,min_label+2);
      then
        next_vertex::inQueue;
    else
      then
        inQueue;
  end matchcontinue;
end PR_FIFO_FAIRrelabel;


// =============================================================================
// cheap matching implementations
//
// =============================================================================

protected function cheapmatchingalgorithm
"function cheapmatchingalgorithm, traverses all colums and look for a cheap matching, a unmatch row
 author: Frenkel TUD 2012-07"
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input Boolean intRangeUsed;
  output list<Integer> outUnMatched;
algorithm
  outUnMatched := cheapmatchingalgorithm1(Config.getCheapMatchingAlgorithm(),nv,ne,m,mT,ass1,ass2,intRangeUsed);
end cheapmatchingalgorithm;

protected function cheapmatchingalgorithm1
" author: Frenkel TUD 2012-07"
  input Integer algorithmid;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input Boolean intRangeUsed;
  output list<Integer> outUnMatched;
algorithm
  outUnMatched := match(algorithmid,nv,ne,m,mT,ass1,ass2,intRangeUsed)
    case(1,_,_,_,_,_,_,_) then cheapmatching(1,nv,ne,m,mT,ass1,ass2,{});
    case(3,_,_,_,_,_,_,_) then ks_rand_cheapmatching(nv,ne,m,mT,ass1,ass2);
    case(_,_,_,_,_,_,_,true) then getUnassigned(ne, ass1, {});
    else {};
  end match;
end cheapmatchingalgorithm1;

protected function cheapmatching
"function cheapmatching, traverses all colums and look for a cheap matching, a unmatch row
 author: Frenkel TUD 2012-03"
  input Integer i;
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input list<Integer> inUnMatched;
  output list<Integer> outUnMatched;
algorithm
  outUnMatched:=
  matchcontinue (i,nv,ne,m,mT,ass1,ass2,inUnMatched)
    local
      list<Integer> rows;
    case (_,_,_,_,_,_,_,_)
      equation
        true=intGt(i,ne);
      then
        inUnMatched;
    case (_,_,_,_,_,_,_,_)
      equation
        // search cheap matching
        rows = List.select(m[i], Util.intPositive);
        cheapmatching1(rows,i,ass1,ass2);
      then
        cheapmatching(i+1,nv,ne,m,mT,ass1,ass2,inUnMatched);
    case (_,_,_,_,_,_,_,_)
        // unmatched add to list
      then
        cheapmatching(i+1,nv,ne,m,mT,ass1,ass2,i::inUnMatched);
    else
      equation
        Error.addInternalError("function cheapmatching failed in equation " + intString(i), sourceInfo());
      then
        fail();
  end matchcontinue;
end cheapmatching;

protected function cheapmatching1
"function helper for cheapmatching, traverses all rows, fails if no unmatched is found
 author: Frenkel TUD 2012-03"
  input list<Integer> rows;
  input Integer c;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
algorithm
  _:=
  matchcontinue (rows,c,ass1,ass2)
    local
      list<Integer> rest;
      Integer r;
    case (r::_,_,_,_)
      equation
        // row is unmatched -> return
        true = intLt(ass2[r],0);
        arrayUpdate(ass1,c,r);
        arrayUpdate(ass2,r,c);
      then
        ();
    case (_::rest,_,_,_)
      equation
        cheapmatching1(rest,c,ass1,ass2);
      then
        ();
  end matchcontinue;
end cheapmatching1;

protected function ks_rand_cheapmatching
"function ks_rand_cheapmatching, Random Karp-Sipser
 author: Frenkel TUD 2012-04"
  input Integer nv;
  input Integer ne;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  output list<Integer> outUnMatched;
protected
  list<Integer> onecolums, onerows;
  array<Integer> col_degrees, row_degrees,randarr;
algorithm
  col_degrees := arrayCreate(ne,0);
  row_degrees := arrayCreate(ne,0);
  onerows := getOneRows(ne,mT,row_degrees,{});
  onecolums := getOneRows(nv,m,col_degrees,{});
  randarr := listArray(List.intRange(ne));
  setrandArray(ne,randarr);
  ks_rand_cheapmatching1(1,ne,onecolums,onerows,col_degrees,row_degrees,randarr,m,mT,ass1,ass2);
  outUnMatched := getUnassigned(ne,ass1,{});
end ks_rand_cheapmatching;

protected function ks_rand_cheapmatching1
"function ks_rand_cheapmatching1, helper for ks_rand_cheapmatching.
 author: Frenkel TUD 2012-04"
  input Integer i;
  input Integer ne;
  input list<Integer> onecolums;
  input list<Integer> onerows;
  input array<Integer> col_degrees;
  input array<Integer> row_degrees;
  input array<Integer> randarr;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
algorithm
  _ := matchcontinue (i,ne,onecolums,onerows,col_degrees,row_degrees,randarr,m,mT,ass1,ass2)
    local
      list<Integer> onecolums1,onerows1;
      Integer c;
      Boolean b;
      case (_,_,_,_,_,_,_,_,_,_,_)
        equation
          false = intLe(i,ne);
        then
          ();
      case (_,_,_,_,_,_,_,_,_,_,_)
        equation
          ks_rand_match(onerows,onecolums,row_degrees,col_degrees,mT,m,ass2,ass1);
          c = randarr[i];
          b = intLt(ass1[c],0) and intGt(col_degrees[c],0);
          (onecolums1,onerows1) = ks_rand_cheapmatching2(b,c,col_degrees,row_degrees,randarr,m,mT,ass1,ass2);
          ks_rand_cheapmatching1(i+1,ne,onecolums1,onerows1,col_degrees,row_degrees,randarr,m,mT,ass1,ass2);
        then
          ();
    end matchcontinue;
end ks_rand_cheapmatching1;

protected function ks_rand_cheapmatching2
"function ks_rand_cheapmatching2, helper for ks_rand_cheapmatching.
 author: Frenkel TUD 2012-04"
  input Boolean b;
  input Integer c;
  input array<Integer> col_degrees;
  input array<Integer> row_degrees;
  input array<Integer> randarr;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output list<Integer> onecolums;
  output list<Integer> onerows;
algorithm
  (onecolums,onerows) := match (b,c,col_degrees,row_degrees,randarr,m,mT,ass1,ass2)
    local
      list<Integer> clst,rlst,lst;
      Integer e_id,r;
    case (true,_,_,_,_,_,_,_,_)
      equation
        e_id = realInt(realMod(System.realRand(),intReal(col_degrees[c])));
        lst = List.select(m[c], Util.intPositive);
        (rlst,r) = ks_rand_cheapmatching3(e_id,lst,row_degrees,c,ass1,ass2,{},0);
        lst = List.select(mT[r], Util.intPositive);
        clst = ks_rand_cheapmatching4(lst,row_degrees[r],col_degrees,ass1,{});
      then
        (clst,rlst);
    else
      ({},{});
  end match;
end ks_rand_cheapmatching2;

protected function ks_rand_cheapmatching3
"function ks_rand_cheapmatching3, helper for ks_rand_match.
 author: Frenkel TUD 2012-04"
  input Integer e_id;
  input list<Integer> rows;
  input array<Integer> row_degrees;
  input Integer c;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> onerows;
  input Integer inR;
  output list<Integer> outonerows;
  output Integer outR;
algorithm
  (outonerows,outR) := matchcontinue(e_id,rows,row_degrees,c,ass1,ass2,onerows,inR)
    local
        list<Integer> rest,stack,statck1;
        Integer r,r_1;
      case (_,{},_,_,_,_,_,_) then (onerows,inR);
      case (_,r::rest,_,_,_,_,_,_)
        equation
          true = intLt(ass2[r],0);
          true = intEq(e_id,0);
          arrayUpdate(ass1,c,r);
          arrayUpdate(ass2,r,c);
          stack = ks_rand_match_degree(rest,row_degrees,ass2,onerows);
        then
          (stack,r);
      case (_,r::rest,_,_,_,_,_,_)
        equation
           true = intLt(ass2[r],0);
          arrayUpdate(row_degrees,r,row_degrees[r]-1);
          stack = List.consOnTrue(intEq(row_degrees[r],1),r,onerows);
         (statck1,r_1) = ks_rand_cheapmatching3(e_id-1,rest,row_degrees,c,ass1,ass2,stack,r);
        then
          (statck1,r_1);
      case (_,r::rest,_,_,_,_,_,_)
        equation
         (statck1,r_1) = ks_rand_cheapmatching3(e_id-1,rest,row_degrees,c,ass1,ass2,onerows,r);
        then
          (statck1,r_1);
    end matchcontinue;
end ks_rand_cheapmatching3;

protected function ks_rand_cheapmatching4
"function ks_rand_cheapmatching4, helper for ks_rand_cheapmatching.
 author: Frenkel TUD 2012-04"
  input list<Integer> cols;
  input Integer count;
  input array<Integer> col_degrees;
  input array<Integer> ass1 "eqn := ass1[var]";
  input list<Integer> inStack;
  output list<Integer> outStack;
algorithm
  outStack := matchcontinue(cols,count,col_degrees,ass1,inStack)
    local
        list<Integer> rest,stack;
        Integer c;
      case ({},_,_,_,_) then inStack;
      case (_,_,_,_,_)
        equation
          false = intGt(count,0);
        then
          inStack;
      case (c::rest,_,_,_,_)
        equation
          true = intLt(ass1[c],0);
          arrayUpdate(col_degrees,c,col_degrees[c]-1);
          stack = List.consOnTrue(intEq(col_degrees[c],1),c,inStack);
        then
          ks_rand_cheapmatching4(rest,count-1,col_degrees,ass1,stack);
      case (_::rest,_,_,_,_)
        then
         ks_rand_cheapmatching4(rest,count,col_degrees,ass1,inStack);
    end matchcontinue;
end ks_rand_cheapmatching4;

protected function getOneRows
"function getOneRows, helper for ks_rand_cheapmatching.
 return all rows with length == 1
 author: Frenkel TUD 2012-04"
 input Integer n;
 input BackendDAE.IncidenceMatrix m;
 input array<Integer> degrees;
 input list<Integer> inOneRows;
 output list<Integer> outOneRows;
algorithm
 outOneRows := match(n,m,degrees,inOneRows)
    local
      list<Integer> lst,onerows;
      Integer l;
    case(0,_,_,_) then listReverse(inOneRows);
    else
      equation
        lst = List.select(m[n], Util.intPositive);
        l = listLength(lst);
        arrayUpdate(degrees,n,l);
        onerows = List.consOnTrue(intEq(l,1),n,inOneRows);
     then
        getOneRows(n-1,m,degrees,onerows);
  end match;
end getOneRows;

protected function setrandArray
"function setrandArray, helper for ks_rand_cheapmatching.
 return all rows with length == 1
 author: Frenkel TUD 2012-04"
 input Integer n;
 input array<Integer> randarr;
algorithm
 _ := match(n,randarr)
    local
      Integer z,tmp;
    case(0,_) then ();
    else
      equation
        z = realInt(realMod(System.realRand(),intReal(n)))+1;
        tmp = randarr[n];
        arrayUpdate(randarr,n,randarr[z]);
        arrayUpdate(randarr,z,tmp);
        setrandArray(n-1,randarr);
     then
       ();
  end match;
end setrandArray;

protected function ks_rand_match
"function ks_rand_match, helper for ks_rand_cheapmatching.
 author: Frenkel TUD 2012-04"
  input list<Integer> stack1;
  input list<Integer> stack2;
  input array<Integer> degrees1;
  input array<Integer> degrees2;
  input BackendDAE.IncidenceMatrix m1;
  input BackendDAE.IncidenceMatrix m2;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
algorithm
  _ := matchcontinue (stack1,stack2,degrees1,degrees2,m1,m2,ass1,ass2)
    local
      Integer e;
      list<Integer> rest,lst,stack;
    case ({},{},_,_,_,_,_,_) then ();
    case (e::rest,{},_,_,_,_,_,_)
      equation
        true = intEq(degrees1[e],1);
        true = intLt(ass1[e],0);
        lst = List.select(m1[e], Util.intPositive);
        stack = ks_rand_match1(e,lst,rest,degrees1,degrees2,m2,ass1,ass2);
        ks_rand_match(stack,{},degrees1,degrees2,m1,m2,ass1,ass2);
      then
        ();
    case (_::rest,{},_,_,_,_,_,_)
      equation
        ks_rand_match(rest,{},degrees1,degrees2,m1,m2,ass1,ass2);
      then
        ();
    case ({},e::rest,_,_,_,_,_,_)
      equation
        true = intEq(degrees2[e],1);
        true = intLt(ass2[e],0);
        lst = List.select(m2[e], Util.intPositive);
        stack = ks_rand_match1(e,lst,rest,degrees2,degrees1,m1,ass2,ass1);
        ks_rand_match(stack,{},degrees2,degrees1,m2,m1,ass2,ass1);
      then
        ();
    case ({},_::rest,_,_,_,_,_,_)
      equation
        ks_rand_match(rest,{},degrees2,degrees1,m2,m1,ass2,ass1);
      then
        ();
    case (e::rest,_,_,_,_,_,_,_)
      equation
        true = intEq(degrees1[e],1);
        true = intLt(ass1[e],0);
        lst = List.select(m1[e], Util.intPositive);
        stack = ks_rand_match1(e,lst,rest,degrees1,degrees2,m2,ass1,ass2);
        ks_rand_match(stack2,stack,degrees2,degrees1,m2,m1,ass2,ass1);
      then
        ();
    case (_::rest,_,_,_,_,_,_,_)
      equation
        ks_rand_match(stack2,rest,degrees2,degrees1,m2,m1,ass2,ass1);
      then
        ();
  end matchcontinue;
end ks_rand_match;

protected function ks_rand_match1
"function ks_rand_match1, helper for ks_rand_match.
 author: Frenkel TUD 2012-04"
  input Integer i;
  input list<Integer> entries;
  input list<Integer> stack;
  input array<Integer> degrees1;
  input array<Integer> degrees2;
  input BackendDAE.IncidenceMatrix incidence;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  output list<Integer> outStack;
algorithm
  outStack := matchcontinue(i,entries,stack,degrees1,degrees2,incidence,ass1,ass2)
    local
        list<Integer> rest,lst;
        Integer e;
      case (_,{},_,_,_,_,_,_) then stack;
      case (_,e::_,_,_,_,_,_,_)
        equation
          true = intLt(ass2[e],0);
          lst = List.select(incidence[e], Util.intPositive);
          arrayUpdate(ass1,i,e);
          arrayUpdate(ass2,e,i);
        then
          ks_rand_match_degree(lst,degrees1,ass1,stack);
      case (_,_::rest,_,_,_,_,_,_)
        then
          ks_rand_match1(i,rest,stack,degrees1,degrees2,incidence,ass1,ass2);
    end matchcontinue;
end ks_rand_match1;

protected function ks_rand_match_degree
"function ks_rand_match_degree, helper for ks_rand_match.
 author: Frenkel TUD 2012-04"
  input list<Integer> entries;
  input array<Integer> degrees;
  input array<Integer> ass;
  input list<Integer> inStack;
  output list<Integer> outStack;
algorithm
  outStack := matchcontinue(entries,degrees,ass,inStack)
    local
        list<Integer> rest,stack;
        Integer e;
      case ({},_,_,_) then inStack;
      case (e::rest,_,_,_)
        equation
          true = intLt(ass[e],0);
          arrayUpdate(degrees,e,degrees[e]-1);
          stack = List.consOnTrue(intEq(degrees[e],1),e,inStack);
        then
          ks_rand_match_degree(rest,degrees,ass,stack);
      case (_::rest,_,_,_)
        then
         ks_rand_match_degree(rest,degrees,ass,inStack);
    end matchcontinue;
end ks_rand_match_degree;

// =============================================================================
// C-Implementation Stuff from
// Kamer Kaya, Johannes Langguth and Bora Ucar
// see: http://bmi.osu.edu/~kamer/index.html
// =============================================================================

public function DFSBExternal
"function: DFSBExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        true = if not clearMatching then BackendDAEEXT.setAssignment(neqns, nvars, vec1, vec2) else true;
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,1,Config.getCheapMatchingAlgorithm(),if clearMatching then 1 else 0,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.DFSBExternal failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end DFSBExternal;

public function BFSBExternal
"function: BFSBExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        true = if not clearMatching then BackendDAEEXT.setAssignment(neqns, nvars, vec1, vec2) else true;
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,2,Config.getCheapMatchingAlgorithm(),if clearMatching then 1 else 0,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.BFSBExternal failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end BFSBExternal;

public function MC21AExternal
"function: MC21AExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        true = if not clearMatching then BackendDAEEXT.setAssignment(neqns, nvars, vec1, vec2) else true;
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,3,Config.getCheapMatchingAlgorithm(),if clearMatching then 1 else 0,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.MC21AExternal failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end MC21AExternal;

public function PFExternal
"function: PFExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        true = if not clearMatching then BackendDAEEXT.setAssignment(neqns, nvars, vec1, vec2) else true;
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,4,Config.getCheapMatchingAlgorithm(),if clearMatching then 1 else 0,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.PFExternal failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end PFExternal;

public function PFPlusExternal
"function: PFExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        true = if not clearMatching then BackendDAEEXT.setAssignment(neqns, nvars, vec1, vec2) else true;
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,5,Config.getCheapMatchingAlgorithm(),if clearMatching then 1 else 0,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.PFPlusExternal failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end PFPlusExternal;

public function HKExternal
"function: HKExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        true = if not clearMatching then BackendDAEEXT.setAssignment(neqns, nvars, vec1, vec2) else true;
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,6,Config.getCheapMatchingAlgorithm(),if clearMatching then 1 else 0,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.HKExternal failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end HKExternal;

public function HKDWExternal
"function: HKDWExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        true = if not clearMatching then BackendDAEEXT.setAssignment(neqns, nvars, vec1, vec2) else true;
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,7,Config.getCheapMatchingAlgorithm(),if clearMatching then 1 else 0,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.HKDWExternal failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end HKDWExternal;

public function ABMPExternal
"function: ABMPExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        true = if not clearMatching then BackendDAEEXT.setAssignment(neqns, nvars, vec1, vec2) else true;
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,8,Config.getCheapMatchingAlgorithm(),if clearMatching then 1 else 0,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.ABMPExternal failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end ABMPExternal;

public function PR_FIFO_FAIRExternal
"function: PR_FIFO_FAIRExternal"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Boolean clearMatching;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (osyst,oshared,outArg) :=
  matchcontinue (isyst,ishared,clearMatching,inMatchingOptions,sssHandler,inArg)
    local
      Integer nvars,neqns;
      array<Integer> vec1,vec2;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        true = intGt(nvars,0);
        true = intGt(neqns,0);
        (vec1,vec2) = getAssignment(clearMatching,nvars,neqns,isyst);
        true = if not clearMatching then BackendDAEEXT.setAssignment(neqns, nvars, vec1, vec2) else true;
        (vec1,vec2,syst,shared,arg) = matchingExternal({},false,10,Config.getCheapMatchingAlgorithm(),if clearMatching then 1 else 0,isyst,ishared,nvars, neqns, vec1, vec2, inMatchingOptions, sssHandler, inArg);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,shared,arg);
    // fail case if system is empty
    case (_,_,_,_,_,_)
      equation
        neqns = BackendDAEUtil.systemSize(isyst);
        nvars = BackendVariable.daenumVariables(isyst);
        false = intGt(nvars,0);
        false = intGt(neqns,0);
        vec1 = listArray({});
        vec2 = listArray({});
        syst = BackendDAEUtil.setEqSystMatching(isyst,BackendDAE.MATCHING(vec2,vec1,{}));
      then
        (syst,ishared,inArg);
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("- Matching.PR_FIFO_FAIRExternal failed\n");
        end if;
      then
        fail();
  end matchcontinue;
end PR_FIFO_FAIRExternal;

protected function matchingExternal
"function: matchingExternal, helper for external matching algorithms
  author: Frenkel TUD"
  input list<list<Integer>> meqns "Marked Equations for Index Reduction";
  input Boolean internalCall "true if function is called from it self";
  input Integer algIndx "Index of the algorithm, see BackendDAEEXT.matching";
  input Integer cheapMatching "Method for cheap Matching";
  input Integer clearMatching;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outAss1,outAss2,osyst,oshared,outArg):=
  match (meqns,internalCall,algIndx,cheapMatching,clearMatching,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      BackendDAE.IncidenceMatrix m,mt, m1,m1t;
      Integer nv_1,ne_1,memsize;
      list<Integer> unmatched1, meqs_short;
      list<list<Integer>> meqns1, meqns1_0;
      BackendDAE.StructurallySingularSystemHandlerArg arg,arg1;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> ass1_1,ass1_2,ass1_3,ass2_1,ass2_2,ass2_3;
    case ({},true,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        (ass1,ass2,isyst,ishared,inArg);
    case ({},false,_,_,_,BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt)),_,_,_,_,_,_,_,_)
      equation
        matchingExternalsetIncidenceMatrix(nv,ne,m);
        BackendDAEEXT.matching(nv,ne,algIndx,cheapMatching,1.0,clearMatching);
        BackendDAEEXT.getAssignment(ass1,ass2);
        unmatched1 = getUnassigned(ne, ass1, {});
          //BackendDump.dumpEqSystem(isyst, "EQSYS");
        if Flags.isSet(Flags.BLT_DUMP) then print("unmatched equations: "+stringDelimitList(List.map(unmatched1,intString),", ")+"\n\n"); end if;

        // remove some edges which do not have to be traversed when finding the MSSS
        m1 = arrayCopy(m);
        m1t = arrayCopy(mt);
        (m1,m1t) = removeEdgesForNoDerivativeFunctionInputs(m1,m1t,isyst,ishared);
        meqns1 = getEqnsforIndexReduction(unmatched1,ne,m1,m1t,ass1,ass2,inArg);
        if Flags.isSet(Flags.BLT_DUMP) then print("MSS subsets: "+stringDelimitList(List.map(meqns1,Util.intLstString),"\n ")+"\n"); end if;

        //Debug information
          //if listLength(List.flatten(meqns1)) >= 5 then meqs_short = List.firstN(List.flatten(meqns1),5); else meqs_short = List.flatten(meqns1); end if;
          //BackendDump.dumpBipartiteGraphEqSystem(isyst,ishared,"MSSS_"+stringDelimitList(List.map(meqs_short,intString),"_"));

        (ass1_1,ass2_1,syst,shared,arg) = matchingExternal(meqns1,true,algIndx,-1,0,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg);
      then
        (ass1_1,ass2_1,syst,shared,arg);
    case (_::_,_,_,_,_,_,_,_,_,_,_,(BackendDAE.INDEX_REDUCTION(),_),_,_)
      equation
        memsize = arrayLength(ass1);
        (_,_,syst,shared,ass2_1,ass1_1,arg) = sssHandler(meqns,0,isyst,ishared,ass2,ass1,inArg);
        ne_1 = BackendDAEUtil.systemSize(syst);
        nv_1 = BackendVariable.daenumVariables(syst);
        ass1_2 = assignmentsArrayExpand(ass1_1,ne_1,memsize,-1);
        ass2_2 = assignmentsArrayExpand(ass2_1,nv_1,memsize,-1);
        true = BackendDAEEXT.setAssignment(ne_1,nv_1,ass1_2,ass2_2);
        (ass1_3,ass2_3,syst,shared,arg1) = matchingExternal({},false,algIndx,cheapMatching,clearMatching,syst,shared,nv_1,ne_1,ass1_2,ass2_2,inMatchingOptions,sssHandler,arg);
      then
        (ass1_3,ass2_3,syst,shared,arg1);

    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        singularSystemError(meqns,0,isyst,ishared,ass1,ass2,inArg);
      then
        fail();

  end match;
end matchingExternal;

protected function removeEdgesForNoDerivativeFunctionInputs"when gathering the minimal structurally singular subsets from the unmatches equations,
some edges dont have to be considered e.g. edges between a function call and an input variable if the input variable will not be derived when deriving the function
author: Waurich TUD 10-2015"
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input BackendDAE.EqSystem sys;
  input BackendDAE.Shared shared;
  output BackendDAE.IncidenceMatrix mOut;
  output BackendDAE.IncidenceMatrixT mtOut;
protected
  Boolean hasNoDerAnno;
  Integer idx, varIdx;
  list<Integer> varIdxs, row;
  BackendDAE.EquationArray eqs;
  BackendDAE.Variables vars;
  DAE.FunctionTree functionTree;
  list<DAE.ComponentRef> noDerInputs;
algorithm
  vars := sys.orderedVars;
  eqs := sys.orderedEqs;
  functionTree := shared.functionTree;
  idx := 1;
  for eq in BackendEquation.equationList(eqs) loop
    (hasNoDerAnno,noDerInputs) := BackendDAEUtil.isFuncCallWithNoDerAnnotation(eq,functionTree);
    if hasNoDerAnno then
      (_,varIdxs) := BackendVariable.getVarLst(noDerInputs,vars,{},{});
        //print("remove edges between eq: "+intString(idx)+" and vars "+stringDelimitList(List.map(varIdxs,intString),", ")+"\n");
      //update m
      row := m[idx];
      (_,row,_) := List.intersection1OnTrue(row,varIdxs,intEq);
      arrayUpdate(m,idx,row);
      //update mt
      for varIdx in varIdxs loop
        row := arrayGet(m,varIdx);
        row := List.deleteMember(row,idx);
        arrayUpdate(mt,varIdx,row);
      end for;
    end if;
    idx := idx+1;
  end for;
  mOut := m;
  mtOut := mt;
end removeEdgesForNoDerivativeFunctionInputs;

protected function countincidenceMatrixElementEntries
  input Integer i;
  input Integer inCount;
  output Integer outCount;
algorithm
  outCount := if intGt(i,0) then inCount+1 else inCount;
end countincidenceMatrixElementEntries;

protected function countincidenceMatrixEntries
  input Integer i;
  input BackendDAE.IncidenceMatrix m;
  input Integer inCount;
  output Integer outCount;
algorithm
  outCount := match(i,m,inCount)
    local
      Integer l;
    case(0,_,_) then inCount;
    else
      equation
        l = List.fold(m[i], countincidenceMatrixElementEntries, inCount);
      then
        countincidenceMatrixEntries(i-1,m,l);
  end match;
end countincidenceMatrixEntries;

public function matchingExternalsetIncidenceMatrix
"author: Frenkel TUD 2012-04
  "
  input Integer nv;
  input Integer ne;
  input array<list<Integer>> m;
protected
 Integer nz;
algorithm
  nz := countincidenceMatrixEntries(ne,m,0);
  BackendDAEEXT.setIncidenceMatrix(nv,ne,nz,m);
end matchingExternalsetIncidenceMatrix;

// =============================================================================
// Util Functions
//
// =============================================================================

public function reachableEquations "author: lochel
  Returns a list of reachable nodes (equations), corresponding
  to those equations that uses the solved variable of this equation.
  The edges of the graph that identifies strong components/blocks are
  dependencies between blocks. A directed edge e = (n1, n2) means
  that n1 solves for a variable (e.g. \'a\') that is used in the equation
  of n2, i.e. the equation of n1 must be solved before the equation of n2."
  input Integer eqn;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass2 "var := ass2[eqn]";
  output list<Integer> outEqNodes;
protected
  Integer var;
  list<Integer> reachable;
algorithm
  var := ass2[eqn] "get the variable that is solved in given equation";
  reachable := if var > 0 then mT[var] else {} "get the equations that depend on that variable";
  reachable := List.select(reachable, Util.intGreaterZero) "just keep positive integers";
  outEqNodes := List.removeOnTrue(eqn, intEq, reachable);
end reachableEquations;

public function incomingEquations "author: lochel
  Returns a list of incoming nodes (equations), corresponding
  to those variables that occur in this equation."
  input Integer eqn;
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> ass1 "eqn := ass1[var]";
  output list<Integer> outEqNodes;
protected
  list<Integer> vars;
algorithm
  vars := List.select(m[eqn], Util.intGreaterZero) "just keep positive integers";
  outEqNodes := list(ass1[var] for var guard(ass1[var] > 0) in vars);
  outEqNodes := List.removeOnTrue(eqn, intEq, outEqNodes);
end incomingEquations;

public function isAssigned
"author: Frenkel TUD 2012-05"
  input array<Integer> ass;
  input Integer i;
  output Boolean b;
algorithm
  b := intGt(ass[intAbs(i)],0);
end isAssigned;

public function isUnAssigned
"author: Frenkel TUD 2012-05"
  input array<Integer> ass;
  input Integer i;
  output Boolean b;
algorithm
  b := intLt(ass[intAbs(i)],1);
end isUnAssigned;

public function getMarked
"author: Frenkel TUD 2012-05"
  input Integer ne;
  input Integer mark;
  input array<Integer> markArr;
  input list<Integer> iMarked;
  output list<Integer> oMarked;
algorithm
  oMarked := match(ne,mark,markArr,iMarked)
    local
      list<Integer> marked;
    case (0,_,_,_)
      then
        iMarked;
    case (_,_,_,_)
      equation
        marked = List.consOnTrue(intEq(markArr[ne],mark), ne, iMarked);
      then
        getMarked(ne-1,mark,markArr,marked);
  end match;
end getMarked;

public function getUnassigned "author: Frenkel TUD 2012-05
  return all Indixes with ass[indx]<1, traverses the
  array from the ne element to the first."
  input Integer ne;
  input array<Integer> ass;
  input list<Integer> inUnassigned;
  output list<Integer> outUnassigned;
algorithm
  outUnassigned := match(ne,ass,inUnassigned)
    local
      list<Integer> unassigned;
    case (0,_,_)
      then
        inUnassigned;
    case (_,_,_)
      equation
        unassigned = List.consOnTrue(intLt(ass[ne],1), ne, inUnassigned);
      then
        getUnassigned(ne-1,ass,unassigned);
  end match;
end getUnassigned;

public function getAssignedArray "author: lochel"
  input array<Integer> ass;
  output array<Boolean> outIsAssigned;
protected
  Integer N = arrayLength(ass);
algorithm
  outIsAssigned := arrayCreate(N, false);
  for i in 1:N loop
    if ass[i] > 0 then
      arrayUpdate(outIsAssigned, i, true);
    end if;
  end for;
end getAssignedArray;

public function getAssigned
"author: Frenkel TUD 2012-05
  return all Indixes with ass[indx]>0, traverses the
  array from the ne element to the first."
  input Integer ne;
  input array<Integer> ass;
  input list<Integer> inAssigned;
  output list<Integer> outAssigned;
algorithm
  outAssigned := match(ne,ass,inAssigned)
    local
      list<Integer> assigned;
    case (0,_,_)
      then
        inAssigned;
    case (_,_,_)
      equation
        assigned = List.consOnTrue(intGt(ass[ne],0), ne, inAssigned);
      then
        getAssigned(ne-1,ass,assigned);
  end match;
end getAssigned;

public function getEqnsforIndexReduction
"function getEqnsforIndexReduction, collect all equations for the index reduction from a given set of
 unmatched equations
 author: Frenkel TUD 2012-04"
  input list<Integer> U;
  input Integer neqns;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output list<list<Integer>> eqns;
algorithm
  eqns := match(U,neqns,m,mT,ass1,ass2,inArg)
    local
      Integer lengthU;
      array<Integer> colummarks;
      array<list<Integer>> mapEqnIncRow,subsets;
      array<Integer> mapIncRowEqn;
    case({},_,_,_,_,_,_) then {};
    case(_,_,_,_,_,_,(_,_,mapEqnIncRow,mapIncRowEqn,_))
      equation
        colummarks = arrayCreate(neqns,-1);
        lengthU = listLength(U);
        subsets = arrayCreate(lengthU,{}) "maximal number of subsets is each unassigned eqn has its own";
        subsets = getEqnsforIndexReduction1(U,m,mT,1,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,subsets);
        // remove empty subsets
      then
        removeEmptySubsets(1,lengthU,subsets,{});
  end match;
end getEqnsforIndexReduction;

protected function removeEmptySubsets
  input Integer index;
  input Integer length;
  input array<list<Integer>> subsets;
  input list<list<Integer>> iAcc;
  output list<list<Integer>> oAcc;
algorithm
  oAcc := matchcontinue(index,length,subsets,iAcc)
    local
      list<Integer> eqns;
      list<list<Integer>> acc;
    case (_,_,_,_)
      equation
        true = intLe(index,length);
        eqns = subsets[index];
        acc = appendNonEmpty(eqns,iAcc);
      then
        removeEmptySubsets(index+1,length,subsets,acc);
    else iAcc;
  end matchcontinue;
end removeEmptySubsets;

protected function appendNonEmpty
  input list<Integer> eqns;
  input list<list<Integer>> iAcc;
  output list<list<Integer>> oAcc;
algorithm
  oAcc := match(eqns,iAcc)
    case ({},_) then iAcc;
    else eqns::iAcc;
  end match;
end appendNonEmpty;

protected function getEqnsforIndexReduction1
"function getEqnsforIndexReduction1, helper for getEqnsforIndexReduction
 author: Frenkel TUD 2012-04"
  input list<Integer> U;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input Integer mark;
  input array<Integer> colummarks;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input array<list<Integer>> mapEqnIncRow "eqn indx -> skalar Eqn indexes";
  input array<Integer> mapIncRowEqn "scalar eqn index -> eqn indx";
  input array<list<Integer>> inSubsets;
  output array<list<Integer>> outSubsets;
algorithm
  outSubsets:= matchcontinue (U,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubsets)
    local
      list<Integer> rest,eqns;
      Integer e,e1;
    case ({},_,_,_,_,_,_,_,_,_) then inSubsets;
    case (e::rest,_,_,_,_,_,_,_,_,_)
      equation
        // row is not visited
        false = intGt(colummarks[e],0);
        // if it is a multi dim equation take all scalare equations
        e1 = mapIncRowEqn[e];
        eqns = mapEqnIncRow[e1];
        _ = List.fold1r(eqns,arrayUpdate,mark,colummarks);
        //  print("Seach for unassigned Eqns " + stringDelimitList(List.map(eqns,intString),", ") + "\n");
        eqns = getEqnsforIndexReductionphase(eqns,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubsets,eqns);
        //  print("Found Eqns " + stringDelimitList(List.map(eqns,intString),", ") + "\n");
        Array.appendToElement(mark,eqns,inSubsets);
      then
        getEqnsforIndexReduction1(rest,m,mT,mark+1,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubsets);
    case (_::rest,_,_,_,_,_,_,_,_,_)
      then
        getEqnsforIndexReduction1(rest,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubsets);
  end matchcontinue;
end getEqnsforIndexReduction1;

protected function getEqnsforIndexReductionphase
"author: Frenkel TUD 2012-04"
  input list<Integer> elst;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input Integer mark;
  input array<Integer> colummarks;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input array<list<Integer>> mapEqnIncRow "eqn indx -> skalar Eqn indexes";
  input array<Integer> mapIncRowEqn "scalar eqn index -> eqn indx";
  input array<list<Integer>> inSubsets;
  input list<Integer> inEqns;
  output list<Integer> outEqns;
algorithm
  outEqns :=
  match (elst,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubsets,inEqns)
    local
      Integer e;
      list<Integer> rows,rest,eqns;
    case ({},_,_,_,_,_,_,_,_,_,_) then inEqns;
    case (e::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows
        rows = List.select(m[e], Util.intPositive);
        //  print("search in Rows " + stringDelimitList(List.map(rows,intString),", ") + " from " + intString(e) + "\n");
        eqns = getEqnsforIndexReductiontraverseRows(rows,{},m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubsets,inEqns);
      then
        getEqnsforIndexReductionphase(rest,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubsets,eqns);
    else
      then
        fail();
  end match;
end getEqnsforIndexReductionphase;

protected function getEqnsforIndexReductiontraverseRows
"author: Frenkel TUD 2012-04"
  input list<Integer> rows;
  input list<Integer> nextColums;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input Integer mark;
  input array<Integer> colummarks;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input array<list<Integer>> mapEqnIncRow "eqn indx -> skalar Eqn indexes";
  input array<Integer> mapIncRowEqn "scalar eqn index -> eqn indx";
  input array<list<Integer>> inSubsets;
  input list<Integer> inEqns;
  output list<Integer> outEqns;
algorithm
  outEqns:=
  matchcontinue (rows,nextColums,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubsets,inEqns)
    local
      list<Integer> rest,queue,nextqueue,eqns;
      Integer rc,r,e,mrc;
      Boolean b;
    case ({},{},_,_,_,_,_,_,_,_,_,_) then inEqns;
    case ({},_,_,_,_,_,_,_,_,_,_,_)
      then
        getEqnsforIndexReductionphase(nextColums,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubsets,inEqns);
    case (r::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is matched
        // print("check Row " + intString(r) + "\n");
        rc = ass2[r];
        // print("check Colum " + intString(rc) + "\n");
        true = intGt(rc,0);
        mrc = colummarks[rc];
        false = intEq(mrc,mark);
        if intGt(colummarks[rc],0) then
          mergeSubsets(mark,mrc,inSubsets,colummarks);
          fail();
        end if;
        // if it is a multi dim equation take all scalare equations
        e = mapIncRowEqn[rc];
        eqns = mapEqnIncRow[e];
        _ = List.fold1r(eqns,arrayUpdate,mark,colummarks);
        //  print("add to nextQueue and Queue " + stringDelimitList(List.map(eqns,intString),", ") + "\n");
        nextqueue = listAppend(nextColums,eqns);
        queue = listAppend(inEqns,eqns);
        //(nextqueue,queue) = getEqnsforIndexReductiontraverseColums(mT[r],colummarks,ass1,rc::nextColums,rc::inEqns);
      then
        getEqnsforIndexReductiontraverseRows(rest,nextqueue,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubsets,queue);
    case (_::rest,_,_,_,_,_,_,_,_,_,_,_)
      then
        getEqnsforIndexReductiontraverseRows(rest,nextColums,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubsets,inEqns);
  end matchcontinue;
end getEqnsforIndexReductiontraverseRows;

protected function mergeSubsets
  input Integer mark;
  input Integer markColum;
  input array<list<Integer>> inSubsets;
  input array<Integer> colummarks;
protected
  list<Integer> eqns;
algorithm
  eqns := inSubsets[markColum];
  Array.appendToElement(mark,eqns,inSubsets);
  arrayUpdate(inSubsets,markColum,{});
  List.fold1r(eqns,arrayUpdate,mark,colummarks);
end mergeSubsets;

protected function reduceIndexifNecessary
"function: reduceIndexifNecessary, calls sssHandler if system need index reduction
  author: Frenkel TUD 2012-04"
  input list<Integer> meqns "Marked Equations for Index Reduction";
  input Integer actualEqn;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer nv;
  input Integer ne;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input BackendDAE.MatchingOptions inMatchingOptions;
  input BackendDAEFunc.StructurallySingularSystemHandlerFunc sssHandler;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output list<Integer> outchangedEqns;
  output Integer continueEqn;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output Integer nvars;
  output Integer neqns;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (outchangedEqns,continueEqn,osyst,oshared,nvars,neqns,outAss1,outAss2,outArg):=
  match (meqns,actualEqn,isyst,ishared,nv,ne,ass1,ass2,inMatchingOptions,sssHandler,inArg)
    local
      Integer nv_1,ne_1,i_1;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<Integer> ass1_1,ass1_2,ass2_1,ass2_2;
      list<Integer> changedEqns;

    case ({},_,_,_,_,_,_,_,_,_,_)
      then
        ({},actualEqn+1,isyst,ishared,nv,ne,ass1,ass2,inArg);
    case (_::_,_,_,_,_,_,_,_,(BackendDAE.INDEX_REDUCTION(),_),_,_)
      equation
        (changedEqns,i_1,syst,shared,ass2_1,ass1_1,arg) = sssHandler({meqns},actualEqn,isyst,ishared,ass2,ass1,inArg);
        ne_1 = BackendDAEUtil.systemSize(syst);
        nv_1 = BackendVariable.daenumVariables(syst);
        ass1_2 = assignmentsArrayExpand(ass1_1,ne_1,arrayLength(ass1_1),-1);
        ass2_2 = assignmentsArrayExpand(ass2_1,nv_1,arrayLength(ass2_1),-1);
      then
        (changedEqns,i_1,syst,shared,nv_1,ne_1,ass1_2,ass2_2,arg);
    case (_,_,_,_,_,_,_,_,_,_,_)
      equation
        singularSystemError({meqns},actualEqn,isyst,ishared,ass1,ass2,inArg);
      then
        fail();
  end match;
end reduceIndexifNecessary;

protected function assignmentsArrayExpand
"function helper for assignmentsArrayExpand
 author: Frenkel TUD 2012-04"
 input array<Integer> ass;
 input Integer needed;
 input Integer memsize;
 input Integer default;
 output array<Integer> outAss;
algorithm
  outAss := matchcontinue(ass,needed,memsize,default)
    case (_,_,_,_)
      equation
        true = intGt(memsize,needed);
      then
        ass;
    case (_,_,_,_)
      equation
        false = intGt(memsize,needed);
      then
        Array.expand(needed-memsize, ass, default);
    else
      equation
        Error.addInternalError("function assignmentsArrayExpand failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end assignmentsArrayExpand;

protected function assignmentsArrayBooleanExpand
"function helper for assignmentsArrayExpand
 author: Frenkel TUD 2012-04"
 input array<Boolean> ass;
 input Integer needed;
 input Integer memsize;
 input Boolean default;
 output array<Boolean> outAss;
algorithm
  outAss := matchcontinue(ass,needed,memsize,default)
    case (_,_,_,_)
      equation
        true = intGt(memsize,needed);
      then
        ass;
    case (_,_,_,_)
      equation
        false = intGt(memsize,needed);
      then
        Array.expand(needed-memsize, ass, default);
    else
      equation
        Error.addInternalError("function assignmentsArrayExpand failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end assignmentsArrayBooleanExpand;

protected function checkAssignment
"author: Frenkel TUD 2012-06
  Check if the assignment is complet/maximum,
  returns all unmatched equations"
  input Integer indx;
  input Integer ne;
  input array<Integer> ass1 "eqn := ass1[var]";
  input array<Integer> ass2 "var := ass2[eqn]";
  input list<Integer> inUnassigned;
  output list<Integer> outUnassigned;
algorithm
  outUnassigned := matchcontinue(indx,ne,ass1,ass2,inUnassigned)
    local
      Integer r,c;
      list<Integer> unassigned;
    case (_,_,_,_,_)
      equation
        true = intGt(indx,ne);
      then
        inUnassigned;
    case (_,_,_,_,_)
      equation
        r = ass1[indx];
        unassigned = List.consOnTrue(intLt(r,0), indx, inUnassigned);
      then
        checkAssignment(indx+1,ne,ass1,ass2,unassigned);
  end matchcontinue;
end checkAssignment;

protected function getAssignment
  input Boolean clearMatching;
  input Integer nVars;
  input Integer nEqns;
  input BackendDAE.EqSystem iSyst;
  output array<Integer> ass1 "ass[eqnindx]=varindx";
  output array<Integer> ass2 "ass[varindx]=eqnindx";
algorithm
  (ass1,ass2) := matchcontinue(clearMatching,nVars,nEqns,iSyst)
    case(false,_,_,BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=ass1,ass2=ass2)))
      equation
        true = intGe(nVars,arrayLength(ass1));
        true = intGe(nEqns,arrayLength(ass2));
      then
        (ass2,ass1);
    else
      equation
        ass2 = arrayCreate(nEqns,-1);
        ass1 = arrayCreate(nVars,-1);
      then
        (ass2,ass1);
  end matchcontinue;
end getAssignment;

// =============================================================================
// tests
//
// =============================================================================

public function testMatchingAlgorithms
"function testMatchingAlgorithms, test all matching algorithms
 author: Frenkel TUD 2012-03"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
protected
  Real t;
  Integer nv,ne,cheapID;
  array<list<Integer>> m;
  array<Integer> vec1,vec2;
  list<Integer> unassigned,meqns;
  list<tuple<String,BackendDAEFunc.matchingAlgorithmFunc>> matchingAlgorithms;
  list<tuple<String,Integer>> extmatchingAlgorithms;
  BackendDAE.EqSystem syst;
algorithm
  ne := BackendDAEUtil.systemSize(isyst);
  nv := BackendVariable.daenumVariables(isyst);
  print("Systemsize: " + intString(ne) + "\n");
  matchingAlgorithms := {("OMCNew:   ",DFSLH),
                         ("BFSB:     ",BFSB),
                         ("DFSB:     ",DFSB),
                         ("MC21A:    ",MC21A),
                         ("PF:       ",PF),
                         ("PFPlus:   ",PFPlus),
                         ("HK:       ",HK),
                         ("HKDW:     ",HKDW),
                         ("ABMP:     ",ABMP),
                         ("PR:       ",PR_FIFO_FAIR)};
  syst := randSortSystem(isyst,ishared);
  testMatchingAlgorithms1(matchingAlgorithms,syst,ishared,inMatchingOptions);

  System.realtimeTick(ClockIndexes.RT_PROFILER0);
  (_,m,_) := BackendDAEUtil.getIncidenceMatrixfromOption(syst,BackendDAE.NORMAL(),NONE());
  matchingExternalsetIncidenceMatrix(nv,ne,m);
  cheapID := 3;
  t := System.realtimeTock(ClockIndexes.RT_PROFILER0);
  print("SetMEXT:     " + realString(t) + "\n");
  extmatchingAlgorithms := {("DFSEXT:   ",1),
                            ("BFSEXT:   ",2),
                            ("MC21AEXT: ",3),
                            ("PFEXT:    ",4),
                            ("PFPlusEXT:",5),
                            ("HKEXT:    ",6),
                            ("HKDWEXT   ",7),
                            ("ABMPEXT   ",8),
                            ("PREXT:    ",10)};
  testExternMatchingAlgorithms1(extmatchingAlgorithms,cheapID,nv,ne);
  System.realtimeTick(ClockIndexes.RT_PROFILER0);
  vec1 := arrayCreate(ne,-1);
  vec2 := arrayCreate(nv,-1);
  BackendDAEEXT.getAssignment(vec1,vec2);
  print("GetAssEXT:   " + realString(t) + "\n");
  System.realtimeTick(ClockIndexes.RT_PROFILER0);
  //unassigned := checkAssignment(1,ne,vec1,vec2,{});
  //print("Unnasigned: " + intString(listLength(unassigned)) + "\n");
  //print("Unassigned:\n");
  //BackendDump.debuglst((unassigned,intString,"\n","\n"));
  //BackendDump.dumpMatching(vec1);
end testMatchingAlgorithms;

public function testMatchingAlgorithms1
"function testMatchingAlgorithms1, helper for testMatchingAlgorithms
 author: Frenkel TUD 2012-04"
  input list<tuple<String,BackendDAEFunc.matchingAlgorithmFunc>> matchingAlgorithms;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
algorithm
  _ :=
  matchcontinue (matchingAlgorithms,isyst,ishared,inMatchingOptions)
      local
        list<tuple<String,BackendDAEFunc.matchingAlgorithmFunc>> rest;
        String str;
        BackendDAEFunc.matchingAlgorithmFunc matchingAlgorithm;
        Real t;
    case ({},_,_,_)
      then ();
    case ((str,matchingAlgorithm)::rest,_,_,_)
      equation
        System.realtimeTick(ClockIndexes.RT_PROFILER0);
        testMatchingAlgorithm(10,matchingAlgorithm,isyst,ishared,inMatchingOptions);
        t = System.realtimeTock(ClockIndexes.RT_PROFILER0);
        print(str + realString(realDiv(t,10.0)) + "\n");
        testMatchingAlgorithms1(rest,isyst,ishared,inMatchingOptions);
      then
        ();
    case ((str,_)::rest,_,_,_)
      equation
        print(str + "failed!\n");
        testMatchingAlgorithms1(rest,isyst,ishared,inMatchingOptions);
      then
        ();
  end matchcontinue;
end testMatchingAlgorithms1;

public function testMatchingAlgorithm
"function testMatchingAlgorithm, tests a specific matching algorithm
 author: Frenkel TUD 2012-04"
  input Integer index;
  input BackendDAEFunc.matchingAlgorithmFunc matchingAlgorithm;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.MatchingOptions inMatchingOptions;
algorithm
  _ :=
  matchcontinue (index,matchingAlgorithm,isyst,ishared,inMatchingOptions)
    local
      BackendDAE.StructurallySingularSystemHandlerArg arg;
    case (0,_,_,_,_)
      then ();
    else
      equation
        arg = IndexReduction.getStructurallySingularSystemHandlerArg(isyst,ishared,listArray({}),listArray({}));
        (_,_,_) = matchingAlgorithm(isyst,ishared,true,inMatchingOptions,IndexReduction.pantelidesIndexReduction,arg);
        testMatchingAlgorithm(index-1,matchingAlgorithm,isyst,ishared,inMatchingOptions);
      then
        ();
  end matchcontinue;
end testMatchingAlgorithm;

public function testExternMatchingAlgorithms1
"function testExternMatchingAlgorithms1, helper for testMatchingAlgorithms
 author: Frenkel TUD 2012-04"
  input list<tuple<String,Integer>> matchingAlgorithms;
  input Integer cheapId;
  input Integer nv;
  input Integer ne;
protected
  String str;
  Integer matchingAlgorithm;
  Real t;
algorithm
  for alg in matchingAlgorithms loop
    (str,matchingAlgorithm) := alg;
    try
      System.realtimeTick(ClockIndexes.RT_PROFILER0);
      testExternMatchingAlgorithm(10,matchingAlgorithm,cheapId,nv,ne);
      t := System.realtimeTock(ClockIndexes.RT_PROFILER0);
      print(str + realString(realDiv(t,10.0)) + "\n");
    else
      print(str + "failed!\n");
    end try;
  end for;
end testExternMatchingAlgorithms1;

public function testExternMatchingAlgorithm
"function testMatchingAlgorithm, tests a specific matching algorithm
 author: Frenkel TUD 2012-04"
  input Integer index;
  input Integer matchingAlgorithm;
  input Integer cheapId;
  input Integer nv;
  input Integer ne;
algorithm
  _ :=
  matchcontinue (index,matchingAlgorithm,cheapId,nv,ne)
    case (0,_,_,_,_)
      then ();
    else
      equation
        BackendDAEEXT.matching(nv,ne,matchingAlgorithm,cheapId,1.0,1);
        testExternMatchingAlgorithm(index-1,matchingAlgorithm,cheapId,nv,ne);
      then
        ();
  end matchcontinue;
end testExternMatchingAlgorithm;

protected function randSortSystem
"function randSortSystem, resort all equations and variables in random order
 author: Frenkel TUD 2012-043"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match isyst
    local
      Integer ne, nv;
      array<Integer> randarr, randarr1;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.EqSystem syst;

   case syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)
     equation
       ne = BackendDAEUtil.systemSize(isyst);
       nv = BackendVariable.daenumVariables(isyst);
       randarr = listArray(List.intRange(ne));
       setrandArray(ne, randarr);
       randarr1 = listArray(List.intRange(nv));
       setrandArray(nv, randarr1);
       syst.orderedEqs = randSortSystem1( ne, 0, randarr, eqns, BackendEquation.listEquation({}),
                                          BackendEquation.equationNth1, BackendEquation.addEquation );
       syst.orderedVars = randSortSystem1( nv, 0, randarr1, vars, BackendVariable.emptyVars(),
                                           BackendVariable.getVarAt, BackendVariable.addVar );
       (syst, _, _) = BackendDAEUtil.getIncidenceMatrix( BackendDAEUtil.clearEqSyst(syst), BackendDAE.NORMAL(), NONE() );
     then
       syst;
  end match;
end randSortSystem;

protected function randSortSystem1
  input Integer index;
  input Integer offset "obsolete";
  input array<Integer> randarr;
  input Type_a oldTypeA;
  input Type_a newTypeA;
  input getFunc get;
  input setFunc set;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function getFunc
    input Type_a inTypeA;
    input Integer inInteger;
    output Type_b outTypeB;
  end getFunc;
  partial function setFunc
    input Type_b inTypeB;
    input Type_a inTypeA;
    output Type_a outTypeA;
  end setFunc;
algorithm
  outTypeA := match(index,offset,randarr,oldTypeA,newTypeA,get,set)
    local
      Type_b tb;
      Type_a ta;
    case (0,_,_,_,_,_,_)
      then newTypeA;
    else
      equation
        tb = get(oldTypeA,randarr[index]+offset);
        ta = set(tb,newTypeA);
      then
       randSortSystem1(index-1,offset,randarr,oldTypeA,ta,get,set);
  end match;
end randSortSystem1;


protected function singularSystemError
  input list<list<Integer>> eqns;
  input Integer actualEqn;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input array<Integer> inAssignments1;
  input array<Integer> inAssignments2;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
protected
  Integer n;
  list<Integer> unmatched,unmatched1,vars;
  String eqn_str,var_str;
  DAE.ElementSource source;
  SourceInfo info;
  array<Integer> mapIncRowEqn;
  BackendDAE.EqSystem syst;
algorithm
  (_,_,_,mapIncRowEqn,_) := inArg;
  n := BackendDAEUtil.systemSize(isyst);
  // for debugging
  /*  BackendDump.printEqSystem(isyst);
    BackendDump.dumpMatching(inAssignments1);
    BackendDump.dumpMatching(inAssignments2);
    syst := BackendDAEUtil.setEqSystMatching(isyst, BackendDAE.MATCHING(inAssignments1,inAssignments2,{}));
    DumpGraphML.dumpSystem(syst,ishared,NONE(),"SingularSystem" + intString(n) + ".graphml",false);
  */
  // get from scalar eqns indexes the indexes in the equation array
  unmatched := List.flatten(eqns);
  unmatched1 := List.map1r(unmatched,arrayGet,mapIncRowEqn);
  unmatched1 := List.uniqueIntN(unmatched1,arrayLength(mapIncRowEqn));
  eqn_str := BackendDump.dumpMarkedEqns(isyst, unmatched1);
  vars := getUnassigned(n, inAssignments2, {});
  vars := List.fold1(unmatched,getAssignedVars,inAssignments1,vars);
  var_str := BackendDump.dumpMarkedVars(isyst, vars);
  source := BackendEquation.markedEquationSource(isyst, listHead(unmatched1));
  info := DAEUtil.getElementSourceFileInfo(source);
  Error.addSourceMessage(Error.STRUCT_SINGULAR_SYSTEM, {eqn_str,var_str}, info);
end singularSystemError;

protected function getAssignedVars
  input Integer e;
  input array<Integer> ass;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
protected
  Integer i;
  Boolean b;
algorithm
  i := ass[e];
  b := intGt(i,0);
  oAcc := List.consOnTrue(b,i,iAcc);
end getAssignedVars;

annotation(__OpenModelica_Interface="backend");
end Matching;
