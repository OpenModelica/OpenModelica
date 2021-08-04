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

encapsulated package Tearing
" file:        Tearing.mo
  package:     Tearing
  description: Tearing contains functions used for tear strong connected components.
               Implemented Methods are:
               - omc tearing developed by TU Dresden: Frenkel,Schubert
               - Cellier Tearing"


import BackendDAE;
import DAE;

protected
import AdjacencyMatrix;
import Array;
import BackendDAEEXT;
import BackendDAEOptimize;
import BackendDAEUtil;
import BackendDump;
import BackendEquation;
import BackendVariable;
import Config;
import DoubleEnded;
import DumpGraphML;
import Error;
import ExecStat.execStat;
import Expression;
import ExpressionDump;
import ExpressionSimplify;
import ExpressionSolve;
import Flags;
import GC;
import Global;
import List;
import Matching;
import MetaModelica.Dangerous;
import Mutable;
import Util;
import Sorting;
import ElementSource;

// =============================================================================
// section for type definitions
//
//
// =============================================================================

protected constant String BORDER    = "****************************************";
protected constant String UNDERLINE = "========================================";

uniontype TearingMethod
  record MINIMAL_TEARING "Only tear discrete variables from loops"
    end MINIMAL_TEARING;
  record GURU_TEARING "Only use tearingSelect.always tearing variables"
    end GURU_TEARING;
  record OMC_TEARING end OMC_TEARING;
  record CELLIER_TEARING end CELLIER_TEARING;
  record TOTAL_TEARING end TOTAL_TEARING;
  record USER_DEFINED_TEARING end USER_DEFINED_TEARING;
end TearingMethod;

// =============================================================================
// section for all public functions
//
// main function to divide to the selected tearing method
// =============================================================================

public function tearingSystem "author: Frenkel TUD 2012-05"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := matchcontinue(inDAE)
    local
      String methodString;
      TearingMethod method;
      BackendDAE.BackendDAEType DAEtype;
      Integer strongComponentIndex = System.tmpTickIndex(Global.strongComponent_index);

    // if noTearing is selected, do nothing.
    case(_) equation
      methodString = Config.getTearingMethod();
      true = stringEqual(methodString, "noTearing");
    then inDAE;

    // get method function and traverse systems
    case(_) equation
      methodString = Config.getTearingMethod();
      BackendDAE.SHARED(backendDAEType=DAEtype) = inDAE.shared;
      false = stringEqual(methodString, "shuffleTearing") and stringEq("simulation",BackendDump.printBackendDAEType2String(DAEtype));
      method = getTearingMethod(methodString);
      if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
        print("\n\n\n\n" + UNDERLINE + UNDERLINE + "\nCalling Tearing for ");
        BackendDump.printBackendDAEType(DAEtype);
        print("!\n" + UNDERLINE + UNDERLINE + "\n");
      end if;
      (outDAE, (_,strongComponentIndex)) = BackendDAEUtil.mapEqSystemAndFold(inDAE, tearingSystemWork, (method, strongComponentIndex));
      System.tmpTickSetIndex(strongComponentIndex, Global.strongComponent_index);
    then outDAE;

    else equation
      Error.addInternalError("./Compiler/BackEnd/Tearing.mo: function tearingSystem failed", sourceInfo());
    then fail();
  end matchcontinue;
end tearingSystem;

// =============================================================================
// protected
//
//
// =============================================================================

protected function getTearingMethod
  input String inTearingMethod;
  output TearingMethod outTearingMethod;
algorithm
  outTearingMethod := match(inTearingMethod)
    case ("minimalTearing") then MINIMAL_TEARING();
    case ("guruTearing") then GURU_TEARING();
    case ("omcTearing") then OMC_TEARING();
    case ("cellier") then CELLIER_TEARING();

    else equation
      Error.addInternalError("./Compiler/BackEnd/Tearing.mo: function getTearingMethod failed", sourceInfo());
    then fail();
  end match;
end getTearingMethod;

protected function callTearingMethod
  input TearingMethod inTearingMethod;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> eindex;
  input list<Integer> vindx;
  input BackendDAE.FullJacobian ojac;
  input BackendDAE.JacobianType jacType;
  input Boolean mixedSystem;
  input Integer strongComponentIndex;
  output BackendDAE.StrongComponent ocomp;
  output Boolean outRunMatching;
protected
  constant Boolean debug = false;
  list<Integer> userTVars, userResiduals;
  TearingMethod tearingMethod = inTearingMethod;
algorithm

  // Check for total tearing for this component
  if listMember(strongComponentIndex, Flags.getConfigIntList(Flags.TOTAL_TEARING)) then
    tearingMethod := TOTAL_TEARING();
  else
    // Get users tearing sets if existing
    userTVars := Flags.getConfigIntList(Flags.SET_TEARING_VARS);
    userResiduals := Flags.getConfigIntList(Flags.SET_RESIDUAL_EQNS);
    (userTVars, userResiduals) := getUserTearingSet(userTVars, userResiduals, strongComponentIndex);

    // Check for user defined tearing for this component
    if not listEmpty(userTVars) and not listEmpty(userResiduals) then
      tearingMethod := USER_DEFINED_TEARING();
    end if;
  end if;

  // Call the appropriate tearing method
  (ocomp, outRunMatching) := match tearingMethod
      case OMC_TEARING()
        algorithm
          if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
            print("\nTearing type: heuristic\n");
            print("Tearing strictness: " + Flags.getConfigString(Flags.TEARING_STRICTNESS) + "\n");
          end if;
          (ocomp,outRunMatching) := omcTearing(isyst, ishared, eindex, vindx, ojac, jacType, mixedSystem);
          if debug then execStat("Tearing.omcTearing"); end if;
        then (ocomp,outRunMatching);

      case CELLIER_TEARING()
        algorithm
          if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
            print("\nTearing type: heuristic\n");
            print("Tearing strictness: " + Flags.getConfigString(Flags.TEARING_STRICTNESS) + "\n");
          end if;
          (ocomp,outRunMatching) := CellierTearing(isyst, ishared, eindex, vindx, userTVars, ojac, jacType, mixedSystem, strongComponentIndex);
          if debug then execStat("Tearing.CellierTearing"); end if;
        then (ocomp,outRunMatching);

      case TOTAL_TEARING()
        algorithm
          if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
            print("\nTearing type: total\n");
            print("Tearing strictness: " + Flags.getConfigString(Flags.TEARING_STRICTNESS) + "\n");
          end if;
          (ocomp,outRunMatching) := totalTearing(isyst, ishared, eindex, vindx, ojac, jacType, mixedSystem);
          if debug then execStat("Tearing.totalTearing"); end if;
        then (ocomp,outRunMatching);

      case MINIMAL_TEARING()
          algorithm
           if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
             print("\nTearing type: minimal\n");
           end if;
           ocomp := minimalTearing(isyst, ishared, eindex, vindx, jacType, mixedSystem);
           if debug then execStat("Tearing.minimalTearing"); end if;
         then (ocomp, true);

      case GURU_TEARING()
          algorithm
           if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
             print("\nTearing type: guru\n");
           end if;
           ocomp := guruTearing(isyst, ishared, eindex, vindx, jacType, mixedSystem);
           if debug then execStat("Tearing.guruTearing"); end if;
         then (ocomp, true);


      case USER_DEFINED_TEARING()
        algorithm
          if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
            print("\nTearing type: user defined\n");
            print("Tearing strictness: " + Flags.getConfigString(Flags.TEARING_STRICTNESS) + "\n");
          end if;
          (ocomp,outRunMatching) := userDefinedTearing(isyst, ishared, eindex, vindx, ojac, jacType, mixedSystem, userTVars, userResiduals);
          if debug then execStat("Tearing.userDefinedTearing"); end if;
        then (ocomp,outRunMatching);
    end match;
end callTearingMethod;

protected function tearingSystemWork "author: Frenkel TUD 2012-05"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared inShared;
  input tuple<TearingMethod,Integer> inTearingMethodAndIndex;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared outShared = inShared "unused";
  output tuple<TearingMethod,Integer> outTearingMethodAndIndex;
protected
  TearingMethod inTearingMethod = Util.tuple21(inTearingMethodAndIndex);
  Integer strongComponentIndex = Util.tuple22(inTearingMethodAndIndex);
  BackendDAE.StrongComponents comps;
  Boolean b;
  array<Integer> ass1, ass2;
algorithm
  BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=ass1, ass2=ass2, comps=comps)):=isyst;
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n" + BORDER + "\nBEGINNING of traverseComponents\n\n");
  end if;

  // Check if maxSizeLinearTearing maxSizeNonlinearTearing flag is illegal
  if (Flags.getConfigInt(Flags.MAX_SIZE_LINEAR_TEARING) < 0) then
    Error.addMessage(Error.INVALID_FLAG_TYPE, {"maxSizeLinearTearing", "non-negative integer", intString(Flags.getConfigInt(Flags.MAX_SIZE_LINEAR_TEARING))});
    fail();
  elseif (Flags.getConfigInt(Flags.MAX_SIZE_NONLINEAR_TEARING) < 0) then
    Error.addMessage(Error.INVALID_FLAG_TYPE, {"maxSizeNonlinearTearing", "non-negative integer", intString(Flags.getConfigInt(Flags.MAX_SIZE_NONLINEAR_TEARING))});
    fail();
  end if;

  (comps, b, strongComponentIndex) := traverseComponents(comps, isyst, inShared, inTearingMethod, strongComponentIndex);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nEND of traverseComponents\n" + BORDER + "\n\n");
  end if;
  osyst := if b then BackendDAEUtil.setEqSystMatching(isyst, BackendDAE.MATCHING(ass1, ass2, comps)) else isyst;
  outTearingMethodAndIndex := (inTearingMethod,strongComponentIndex);
end tearingSystemWork;

protected function traverseComponents "author: Frenkel TUD 2012-05"
  input BackendDAE.StrongComponents inComps;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input TearingMethod inMethod;
  input Integer strongComponentIndexIn;
  output BackendDAE.StrongComponents oComps;
  output Boolean outRunMatching = false;
  output Integer strongComponentIndexOut=strongComponentIndexIn;
algorithm
  oComps := list(match co
        local
          BackendDAE.StrongComponent comp;
          Boolean b;
        case comp
          equation
            (comp, b, strongComponentIndexOut) = traverseComponents1(comp, isyst, ishared, inMethod, strongComponentIndexOut);
            outRunMatching = outRunMatching or b;
          then comp;
        end match for co in inComps);
end traverseComponents;

protected function traverseComponents1 "author: Frenkel TUD 2012-05"
  input BackendDAE.StrongComponent inComp;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input TearingMethod inMethod;
  input Integer strongComponentIndexIn;
  output BackendDAE.StrongComponent oComp;
  output Boolean outRunMatching;
  output Integer strongComponentIndexOut=strongComponentIndexIn;
protected
  constant Boolean debug = false;
  Boolean debugFlag = Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE);
algorithm
  strongComponentIndexOut := match(inComp)
    case(BackendDAE.EQUATIONSYSTEM(jac=BackendDAE.FULL_JACOBIAN())) equation
      if debugFlag then
        print("Handle strong component with index: " + intString(strongComponentIndexOut+1) + "\nTo disable tearing of this component use '--noTearingForComponent=" + intString(strongComponentIndexOut+1) + "'.\n");
      end if;
     then (strongComponentIndexOut + 1);
    else strongComponentIndexOut;
  end match;

  (oComp, outRunMatching) := match (inComp, isyst, ishared, inMethod)
    local
      list<Integer> eindex, vindx;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> ojac;
      BackendDAE.JacobianType jacType;
      Boolean mixedSystem;
      Integer maxSize;
      Boolean isLinear, useTearing;

    // Tearing
    case ((BackendDAE.EQUATIONSYSTEM(eqns=eindex, vars=vindx, jac=BackendDAE.FULL_JACOBIAN(ojac), jacType=jacType, mixedSystem=mixedSystem)), _, _, _) algorithm
      isLinear := BackendDAEUtil.getLinearfromJacType(jacType);
      if isLinear then
        maxSize := Flags.getConfigInt(Flags.MAX_SIZE_LINEAR_TEARING);
      else
        maxSize := Flags.getConfigInt(Flags.MAX_SIZE_NONLINEAR_TEARING);
      end if;

      useTearing := checkTearingSettings(maxSize, isLinear, strongComponentIndexOut, listLength(vindx));
      if useTearing then
        if debugFlag then
          print("\nTearing of " + (if isLinear then "LINEAR" else "NONLINEAR") + " component\n" +
                "Use Flag '-d=tearingdumpV' and '-d=iterationVars' for more details\n\n");
        end if;
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("Jacobian:\n" + BackendDump.dumpJacobianStr(ojac) + "\n\n");
        end if;
        if debug then
          execStat("Tearing.traverseComponents1 " + (if isLinear then "LS" else "NLS") + " start");
        end if;
        try
          oComp := callTearingMethod(inMethod, isyst, ishared, eindex, vindx, ojac, jacType, mixedSystem, strongComponentIndexOut);
          outRunMatching := true;
        else
          oComp := inComp;
          outRunMatching := false;
        end try;
      else
        oComp := inComp;
        outRunMatching := false;
      end if;
    then(oComp, outRunMatching);

    // no component for tearing
    else then(inComp, false);
  end match;
end traverseComponents1;


protected function checkTearingSettings
"Checks if we want to do tearing for the current component.
 It will also issue optional maesages if not."
  input Integer maxSize;
  input Boolean isLinear;
  input Integer strongComponentIndex;
  input Integer numVars;
  output Boolean activateTearing=false;
protected
  Boolean debugFlag = Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE);
  Boolean forcedTearing;
  Boolean isCpp;
  Boolean isDense;
algorithm

  // Check if tearing is disabled (maxSize=0)
  if maxSize == 0 then
    return;
  end if;

  // Check if (numVars < maxSize) or (isCpp and isDense)
  isCpp := stringEqual(Config.simCodeTarget(), "Cpp");
  isDense := stringEqual(Flags.getConfigString(Flags.MATRIX_FORMAT), "dense");
  forcedTearing := isCpp and isDense;
  if numVars > maxSize and not forcedTearing then
    Error.addMessage(Error.MAX_TEARING_SIZE, {intString(strongComponentIndex), intString(numVars), (if isLinear then "linear" else "nonlinear"),intString(maxSize)});
    return;
  end if;

  // Check if tearing is disabled for this component
  if listMember(strongComponentIndex,Flags.getConfigIntList(Flags.NO_TEARING_FOR_COMPONENT)) then
    if debugFlag then
      print("\nTearing deactivated by user.\n");
    end if;
    Error.addMessage(Error.NO_TEARING_FOR_COMPONENT, {intString(strongComponentIndex)});
    return;
  end if;

  activateTearing := true;
end checkTearingSettings;

protected function getUserTearingSet
  input list<Integer> userTVars;
  input list<Integer> userResiduals;
  input Integer strongComponentIndex;
  output list<Integer> userTvarsThisComponent={};
  output list<Integer> userResidualsThisComponent={};
protected
  Integer i=1, start, end_;
  Integer len;
algorithm
  len := listLength(userTVars);
  while i < len loop
      if intEq(listGet(userTVars,i),strongComponentIndex) then
        start := i+2;
        end_ := i + 1 + listGet(userTVars, i+1);
        userTvarsThisComponent := List.unique(selectFromList_rev(userTVars, List.intRange2(start, end_)));
        if not intEq(listLength(userTvarsThisComponent), listGet(userTVars, i+1)) then
          Error.addMessage(Error.USER_DEFINED_TEARING_ERROR, {"The selected tearing variables must have unique indexes."});
          fail();
        end if;
        break;
      else
        i := i + 2 + listGet(userTVars, i+1);
      end if;
  end while;
  if not listEmpty(userTvarsThisComponent) then
    i := 1;
    len := listLength(userResiduals);
    while i < len loop
        if intEq(listGet(userResiduals,i),strongComponentIndex) then
          start := i+2;
          end_ := i + 1 + listGet(userResiduals, i+1);
          userResidualsThisComponent := List.unique(selectFromList_rev(userResiduals, List.intRange2(start, end_)));
          if not intEq(listLength(userResidualsThisComponent), listGet(userResiduals, i+1)) then
            Error.addMessage(Error.USER_DEFINED_TEARING_ERROR, {"The selected residual equations must have unique indexes."});
            fail();
          end if;
          break;
        else
          i := i + 2 + listGet(userResiduals, i+1);
        end if;
    end while;
  end if;
end getUserTearingSet;





// =============================================================================
//
// method: omc tearing
//
// =============================================================================

protected function omcTearing "  author: Frenkel TUD 2012-05"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> eindex;
  input list<Integer> vindx;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> ojac;
  input BackendDAE.JacobianType jacType;
  input Boolean mixedSystem;
  output BackendDAE.StrongComponent ocomp;
  output Boolean outRunMatching;
protected
  list<Integer> tvars,residual,unsolvables;
  list<list<Integer>> othercomps;
  BackendDAE.EqSystem syst,subsyst;
  BackendDAE.Shared shared;
  array<Integer> ass1,ass2,ass22,columark;
  Integer size,tornsize,mark;
  list<BackendDAE.Equation> eqn_lst;
  list<BackendDAE.Var> var_lst;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.AdjacencyMatrix m,m1;
  BackendDAE.AdjacencyMatrix mt,mt1,mt11;
  BackendDAE.AdjacencyMatrixEnhanced me;
  BackendDAE.AdjacencyMatrixTEnhanced meT;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  DAE.FunctionTree funcs;
  list<Integer> asslst1, asslst2;
  list<Integer> tSel_always, tSel_prefer, tSel_avoid, tSel_never;
  String DAEtypeStr;
algorithm
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
     print("\n" + BORDER + "\nBEGINNING of omcTearing\n\n");
  end if;
  DAEtypeStr := BackendDump.printBackendDAEType2String(ishared.backendDAEType);
  // generate Subsystem to get the adjacency matrix
  size := listLength(vindx);
  eqn_lst := BackendEquation.getList(eindex,BackendEquation.getEqnsFromEqSystem(isyst));
  eqns := BackendEquation.listEquation(eqn_lst);
  var_lst := List.map1r(vindx, BackendVariable.getVarAt, BackendVariable.daeVars(isyst));
  vars := BackendVariable.listVar1(var_lst);
  subsyst := BackendDAEUtil.createEqSystem(vars, eqns);
  funcs := BackendDAEUtil.getFunctions(ishared);
  (subsyst,m,mt,_,_) := BackendDAEUtil.getAdjacencyMatrixScalar(subsyst, BackendDAE.NORMAL(), SOME(funcs), BackendDAEUtil.isInitializationDAE(ishared));
     //  DumpGraphML.dumpSystem(subsyst,ishared,NONE(),"System" + intString(size) + ".graphml");
  if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n\n###BEGIN print Strong Component#####################\n(Function:omcTearing)\n");
    BackendDump.printEqSystem(subsyst);
    print("\n###END print Strong Component#######################\n(Function:omcTearing)\n\n\n");
  end if;
  (me,meT,mapEqnIncRow,mapIncRowEqn) := BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(subsyst,ishared,false);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
     print("\n\nAdjacencyMatrixEnhanced:\n");
     BackendDump.dumpAdjacencyMatrixEnhanced(me);
     print("\nAdjacencyMatrixTransposedEnhanced:\n");
     BackendDump.dumpAdjacencyMatrixTEnhanced(meT);
     print("\nmapEqnIncRow:"); //+ stringDelimitList(List.map(List.flatten(arrayList(mapEqnIncRow)),intString),",") + "\n\n");
     BackendDump.dumpAdjacencyMatrix(mapEqnIncRow);
     print("\nmapIncRowEqn:\n" + stringDelimitList(List.map(arrayList(mapIncRowEqn),intString),",") + "\n\n");
  end if;

  ass1 := arrayCreate(size,-1);
  ass2 := arrayCreate(size,-1);
  // get all unsolvable variables
  unsolvables := getUnsolvableVars(size,meT);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
     print("\n\nUnsolvable Vars:\n");
     BackendDump.debuglst(unsolvables,intString,", ","\n");
  end if;
  columark := arrayCreate(size,-1);

  // Collect variables with annotation attribute 'tearingSelect=always', 'tearingSelect=prefer', 'tearingSelect=avoid' and 'tearingSelect=never'
  (tSel_always,tSel_prefer,tSel_avoid,tSel_never) := tearingSelect(var_lst, {}, DAEtypeStr);

  // determine tvars and do cheap matching until a maximum matching is there
  // if cheap matching stucks select additional tearing variable and continue
  // (mark+1 for every call of omcTearing3)
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
     print("\n" + BORDER + "\nBEGINNING of omcTearing2\n\n");
  end if;
  (tvars,mark) := omcTearing2(unsolvables,tSel_always,tSel_prefer,tSel_avoid,tSel_never,me,meT,mapEqnIncRow,mapIncRowEqn,size,vars,ishared,ass1,ass2,columark,1,{});
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
     print("\nEND of omcTearing2\n" + BORDER + "\n\n");
  end if;

  // unassign tvars
  ass1 := List.fold(tvars,unassignTVars,ass1);
  if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
     print("\n" + BORDER + "\n* BFS RESULTS:\n* ass1: "+ stringDelimitList(List.map(arrayList(ass1),intString),",") +"\n");
     print("* ass2: "+ stringDelimitList(List.map(arrayList(ass2),intString),",") + "\n" + BORDER +"\n\n");
  end if;

  // unmatched equations are residual equations
  residual := Matching.getUnassigned(size,ass2,{});
     //  subsyst := BackendDAEUtil.setEqSystMatching(subsyst,BackendDAE.MATCHING(ass1,ass2,{}));
     //  DumpGraphML.dumpSystem(subsyst,ishared,NONE(),"TornSystem" + intString(size) + ".graphml");

  // check if tearing makes sense
  tornsize := listLength(tvars);
  true := intLt(tornsize, size);

  // create adjacency matrices w/o tvar and residual
  m1 := arrayCreate(size,{});
  mt1 := arrayCreate(size,{});
  m1 := AdjacencyMatrix.getOtherEqSysAdjacencyMatrix(m,size,1,ass2,ass1,m1);
  mt1 := AdjacencyMatrix.getOtherEqSysAdjacencyMatrix(mt,size,1,ass1,ass2,mt1);

  // run tarjan to get order of other equations
  othercomps := Sorting.TarjanTransposed(mt1, ass2);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
     print("\nOtherEquationsOrder:\n");
     BackendDump.dumpComponentsOLD(othercomps);
     print("\n");
  end if;

  // calculate influence of tearing vars in residual equations
  // mt1: row=variable, columns: tvars, that influence the result of the variable
  mt1 := arrayCreate(size, {});
  mark := getDependenciesOfVars(othercomps, ass1, ass2, m, mt1, columark, mark);

  (residual, mark) := sortResidualDepentOnTVars(residual, tvars, ass1, m, mt1, columark, mark);
  (ocomp,outRunMatching) := omcTearing4(jacType,isyst,ishared,subsyst,tvars,residual,ass1,ass2,othercomps,eindex,vindx,mapEqnIncRow,mapIncRowEqn,columark,mark,mixedSystem);

  if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
     print(if outRunMatching then "\nStatus:\nOk system torn\n\n" else "\nStatus:\nSystem not torn\n\n");
     print("\n" + BORDER + "\n* TEARING RESULTS:\n*\n* No of equations in strong component: "+intString(size)+"\n");
     print("* No of tVars: "+intString(tornsize)+"\n");
     print("*\n* tVars: "+ stringDelimitList(List.map(tvars,intString),",") + "\n");
     print("*\n* resEq: "+ stringDelimitList(List.map(residual,intString),",") + "\n*\n*");
     BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=tvars,residualequations=residual)) := ocomp;
     print("\n* Related to entire Equationsystem:\n* =====\n* tVars: "+ stringDelimitList(List.map(tvars,intString),",") + "\n* =====\n");
     print("*\n* =====\n* resEq: "+ stringDelimitList(List.map(residual,intString),",") + "\n* =====\n" + BORDER + "\n");
  end if;
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
     print("\n\nStrongComponents:\n");
     BackendDump.dumpComponent(ocomp);
     print("\n\nEND of omcTearing\n" + BORDER + "\n\n");
  end if;
end omcTearing;


protected function getUnsolvableVars
"  author: Frenkel TUD 2012-08"
  input Integer size;
  input BackendDAE.AdjacencyMatrixTEnhanced meT;
  output list<Integer> unsolvables = {};
protected
  Boolean isUnsolvable;
algorithm
  for index in 1:size loop
    isUnsolvable := unsolvable(meT[index]);
    if isUnsolvable then
      unsolvables := index::unsolvables;
    end if;
  end for;
end getUnsolvableVars;


public function unsolvable
"  author: Frenkel TUD 2012-08"
  input BackendDAE.AdjacencyMatrixElementEnhanced elem;
  output Boolean isUnsolvable = true;
protected
  Integer e;
  BackendDAE.Solvability s;
algorithm
  for el in elem loop
    (e,s,_) := el;
    if solvable(s) then
      if e > 0 then
        isUnsolvable := false;
        return;
      end if;
    end if;
  end for;
end unsolvable;


protected function unassignTVars "  author: Frenkel TUD 2012-05"
  input Integer v;
  input array<Integer> inAss;
  output array<Integer> outAss;
algorithm
  outAss := arrayUpdate(inAss,v,-1);
end unassignTVars;




protected function getDependenciesOfVars " function to determine which variables are influenced by the tvars"
  input list<list<Integer>> iComps;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.AdjacencyMatrix m;
  input array<list<Integer>> mT;
  input array<Integer> visited;
  input Integer iMark;
  output Integer oMark;
algorithm
  oMark := match(iComps, ass1, ass2, m, mT, visited, iMark)
    local
      Integer c, v;
      list<Integer> comp, tvars, vars;
      list<list<Integer>> comps;

    case ({}, _, _, _, _, _, _)
    then iMark;

    case ({c}::comps, _, _, _, _, _, _) equation
      // get var of eqn
      v = ass2[c];
      // get TVars of Eqn
      vars = List.select(m[c], Util.intPositive);
      tvars = tVarsofEqn(vars, ass1, mT, visited, iMark, {});
      // update map
      arrayUpdate(mT, v, tvars);
    then getDependenciesOfVars(comps, ass1, ass2, m, mT, visited, iMark+1);

    case (comp::comps, _, _, _, _, _, _) equation
      // get var of eqns
      vars = List.map1r(comp,arrayGet,ass2);
      // get TVars of Eqns
      tvars = tVarsofEqns(comp, m, ass1, mT, visited, iMark);
      // update map
      _ = List.fold1r(vars, arrayUpdate, tvars, mT);
    then getDependenciesOfVars(comps, ass1, ass2, m, mT, visited, iMark+1);
  end match;
end getDependenciesOfVars;


protected function tVarsofEqns "determines tvars that influence this equations"
  input list<Integer> iEqns;
  input BackendDAE.AdjacencyMatrix m;
  input array<Integer> ass1;
  input array<list<Integer>> mT;
  input array<Integer> visited;
  input Integer iMark;
  output list<Integer> oAcc = {};
protected
  list<Integer> vars;
algorithm
  for e in iEqns loop
    vars := List.select(m[e], Util.intPositive);
    oAcc := tVarsofEqn(vars, ass1, mT, visited, iMark, oAcc);
  end for;
end tVarsofEqns;


protected function tVarsofEqn "determines tvars that influence this equation"
  input list<Integer> iVars;
  input array<Integer> ass1;
  input array<list<Integer>> mT;
  input array<Integer> visited;
  input Integer iMark;
  input list<Integer> iAcc;
  output list<Integer> oAcc = iAcc;
algorithm
  for v in iVars loop
    if intLt(ass1[v],0) then
      oAcc := uniqueIntLst(v,iMark,visited,oAcc);
    else
      oAcc := List.fold2(mT[v],uniqueIntLst,iMark,visited,oAcc);
    end if;
  end for;
end tVarsofEqn;


protected function uniqueIntLst
  input Integer c;
  input Integer mark;
  input array<Integer> markarray;
  input list<Integer> iAcc;
  output list<Integer> oAcc = iAcc;
algorithm
  if not intEq(mark,markarray[c]) then
    arrayUpdate(markarray,c,mark);
    oAcc := c::oAcc;
  end if;
end uniqueIntLst;


protected function sortResidualDepentOnTVars
  input list<Integer> iResiduals;
  input list<Integer> iTVars;
  input array<Integer> ass1;
  input BackendDAE.AdjacencyMatrix m;
  input array<list<Integer>> mT;
  input array<Integer> visited;
  input Integer iMark;
  output list<Integer> oResiduals;
  output Integer oMark;
protected
  Integer size;
  list<list<Integer>> maplst;
  array<list<Integer>> map;
  array<Integer> eqnLocalGlobal,varGlobalLocal,v1,v2;
algorithm
  // eqn - local - Global indices
  eqnLocalGlobal := listArray(iResiduals);
  // var - global local indices
  varGlobalLocal := arrayCreate(arrayLength(m),-1);
  varGlobalLocal := getGlobalLocal(iTVars,1,varGlobalLocal);
  // generate list of map[residual]=tvars
  // change indices in map to local
  (oMark,maplst) := tVarsofResidualEqns(iResiduals,m,ass1,mT,varGlobalLocal,visited,iMark);
  map := listArray(maplst);
  // get for each residual a tvar
  size := arrayLength(map);
  Matching.matchingExternalsetAdjacencyMatrix(size,size,map);
  BackendDAEEXT.matching(size,size,5,-1,1.0,1);
  v1 := arrayCreate(size,-1);
  v2 := arrayCreate(size,-1);
  BackendDAEEXT.getAssignment(v2,v1);
  //  BackendDump.dumpAdjacencyMatrix(map);
  //  BackendDump.dumpMatching(v1);
  //  BackendDump.dumpMatching(v2);
  // sort residuals depent on matching to tvars
  oResiduals := getTVarResiduals(size,v1,eqnLocalGlobal,{});
     //print("iResiduals " + stringDelimitList(List.map(iResiduals,intString),",") + "\n");
     //print("oResiduals " + stringDelimitList(List.map(oResiduals,intString),",") + "\n");
end sortResidualDepentOnTVars;


protected function getGlobalLocal
  input list<Integer> iTVars;
  input Integer index;
  input array<Integer> iVarGlobalLocal;
  output array<Integer> oVarGlobalLocal = iVarGlobalLocal;
protected
  Integer idx = index;
algorithm
  for i in iTVars loop
    arrayUpdate(oVarGlobalLocal,i,idx);
    idx := idx + 1;
  end for;
end getGlobalLocal;


protected function tVarsofResidualEqns
  input list<Integer> iEqns;
  input BackendDAE.AdjacencyMatrix m;
  input array<Integer> ass1;
  input array<list<Integer>> mT;
  input array<Integer> varGlobalLocal;
  input array<Integer> visited;
  input Integer iMark;
  output Integer oMark = iMark;
  output list<list<Integer>> oAcc;
algorithm
  oAcc := list(
    match eq
        local
          Integer e;
          list<Integer> eqns,vars,tvars;
        case e
          equation
            vars = List.select(m[e], Util.intPositive);
            tvars = tVarsofEqn(vars,ass1,mT,visited,oMark,{});
            // change indices to local
            tvars = List.map1r(tvars,arrayGet,varGlobalLocal);
            oMark = oMark + 1;
          then tvars;
    end match for eq in iEqns);
end tVarsofResidualEqns;


protected function getTVarResiduals
  input Integer index;
  input array<Integer> v1;
  input array<Integer> eqnLocalGlobal;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
algorithm
  oAcc := match(index,v1,eqnLocalGlobal,iAcc)
    local
      Integer e;
    case (0,_,_,_) then iAcc;
    case (_,_,_,_)
      equation
        e = v1[index];
        e = eqnLocalGlobal[e];
      then
        getTVarResiduals(index-1,v1,eqnLocalGlobal,e::iAcc);
  end match;
end getTVarResiduals;


protected function omcTearing2 " function to determine tvars and do cheap matching
  author: Frenkel TUD 2012-05"
  input list<Integer> unsolvables;
  input list<Integer> tSel_always;
  input list<Integer> tSel_prefer;
  input list<Integer> tSel_avoid;
  input list<Integer> tSel_never;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input Integer size;
  input BackendDAE.Variables vars;
  input BackendDAE.Shared ishared;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<Integer> columark;
  input Integer mark;
  input list<Integer> inTVars;
  output list<Integer> outTVars;
  output Integer oMark;
algorithm
  (outTVars,oMark) := matchcontinue(unsolvables,tSel_always)
    local
      Integer tvar;
      list<Integer> unassigned,rest,ass1List, unsolv;
      BackendDAE.AdjacencyMatrixElementEnhanced vareqns;
    // if there are no unsolvables choose tvar by heuristic
    case ({},{})
      equation
        // select tearing var
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("\n" + BORDER + "\nBEGINNING of omcTearingSelectTearingVar\n\n\n");
        end if;
        tvar = omcTearingSelectTearingVar(vars,ass1,ass2,m,mt,tSel_prefer,tSel_avoid,tSel_never);
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("\nEND of omcTearingSelectTearingVar\n" + BORDER + "\n\n");
        end if;
        // mark tearing var
        arrayUpdate(ass1,tvar,size*2);
        // equations not yet assigned containing the tvar
        vareqns = List.removeOnTrue(ass2, isAssignedSaveEnhanced, mt[tvar]);
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("Assignable equations containing new tvar:\n");
          BackendDump.dumpAdjacencyRowEnhanced(vareqns);
          print("\n");
        end if;
        // cheap matching
        tearingBFS(vareqns,m,mt,mapEqnIncRow,mapIncRowEqn,size,ass1,ass2,{});
        // check for unassigned vars, if there some rerun
        unassigned = Matching.getUnassigned(size,ass1,{});
        (outTVars,oMark) = omcTearing3(unassigned,{},tSel_always,tSel_prefer,tSel_avoid,tSel_never,m,mt,mapEqnIncRow,mapIncRowEqn,size,vars,ishared,ass1,ass2,columark,mark+1,tvar::inTVars);
      then
        (outTVars,oMark);
    // if there are unsolvables choose unsolvables as tvars
    case (tvar::rest,{})
      equation
        if listMember(tvar,tSel_never) then
          Error.addCompilerWarning("There are tearing variables with annotation attribute 'tearingSelect = never'. Use -d=tearingdump and -d=tearingdumpV for more information.");
        end if;
        if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("\nForced selection of Tearing Variable:\n" + UNDERLINE + "\n");
          print("tVar: " + intString(tvar) + " (unsolvable in omcTearing2)\n\n\n");
        end if;
        // mark tearing var
        arrayUpdate(ass1,tvar,size*2);
        // equations not yet assigned containing the tvar
        vareqns = List.removeOnTrue(ass2, isAssignedSaveEnhanced, mt[tvar]);
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("Assignable equations containing new tvar:\n");
          BackendDump.dumpAdjacencyRowEnhanced(vareqns);
          print("\n");
        end if;
        // cheap matching
        tearingBFS(vareqns,m,mt,mapEqnIncRow,mapIncRowEqn,size,ass1,ass2,{});
        // check for unassigned vars, if there some rerun
        unassigned = Matching.getUnassigned(size,ass1,{});
        (outTVars,oMark) = omcTearing3(unassigned,rest,tSel_always,tSel_prefer,tSel_avoid,tSel_never,m,mt,mapEqnIncRow,mapIncRowEqn,size,vars,ishared,ass1,ass2,columark,mark+1,tvar::inTVars);
      then
        (outTVars,oMark);
    case (_,_)
      equation
        if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("\nForced selection of Tearing Variables:\n" + UNDERLINE + "\n");
          print("Variables with annotation attribute 'always' as tVars: " + stringDelimitList(List.map(tSel_always,intString),",")+"\n");
        end if;
        // mark tearing var
        markTVarsOrResiduals(tSel_always, ass1);
        (_,unsolv,_) = List.intersection1OnTrue(unsolvables,tSel_always,intEq);
        // equations not yet assigned containing the tvars
        vareqns = findVareqns(ass2,isAssignedSaveEnhanced,mt,tSel_always);
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("Assignable equations containing new tvars:\n");
          BackendDump.dumpAdjacencyRowEnhanced(vareqns);
          print("\n");
        end if;
        // cheap matching
        tearingBFS(vareqns,m,mt,mapEqnIncRow,mapIncRowEqn,size,ass1,ass2,{});
        // check for unassigned vars, if there some rerun
        unassigned = Matching.getUnassigned(size,ass1,{});
        (outTVars,oMark) = omcTearing3(unassigned,unsolv,{},tSel_prefer,tSel_avoid,tSel_never,m,mt,mapEqnIncRow,mapIncRowEqn,size,vars,ishared,ass1,ass2,columark,mark+1,listAppend(tSel_always,inTVars));
      then
        (outTVars,oMark);
    else
      equation
        print("Tearing.omcTearing2 failed!");
      then
        fail();
  end matchcontinue;
end omcTearing2;


protected function findVareqns
 "Function returns equations not yet assigned containing the currently handled tvars.
  author: ptaeuber FHB 2014-05"
  input array<Integer> ass2In;
  input CompFunc inCompFunc;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input list<Integer> tSel_alwaysIn;
  output list<tuple<Integer,BackendDAE.Solvability,BackendDAE.Constraints>> vareqnsOut = {};
  partial function CompFunc
    input array<Integer> inValue;
    input tuple<Integer,BackendDAE.Solvability,BackendDAE.Constraints> inElement;
    output Boolean outIsEqual;
  end CompFunc;
algorithm
  for tvar in tSel_alwaysIn loop
    vareqnsOut := List.append_reverse(List.removeOnTrue(ass2In,inCompFunc,mt[tvar]), vareqnsOut);
  end for;
  vareqnsOut := List.unique(vareqnsOut);
end findVareqns;


protected function omcTearingSelectTearingVar "  author: Frenkel TUD 2012-05"
  input BackendDAE.Variables vars;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input list<Integer> tSel_prefer;
  input list<Integer> tSel_avoid;
  input list<Integer> tSel_never;
  output Integer tearingVar;
algorithm
  tearingVar := matchcontinue(vars,ass1,ass2,m,mt,tSel_prefer,tSel_avoid,tSel_never)
    local
      list<Integer> freeVars,eqns,unsolvables,pointsLst;
      Integer tvar;
      Integer size,varsize;
      array<Integer> points;
    // if vars there with no linear occurrence in any equation use all of them
/*    case(_,_,_,_)
      equation
      then

    // if states there use them as tearing variables
    case(_,_,_,_)
      equation
        (_,states) = BackendVariable.getAllStateVarIndexFromVariables(vars);
        states = List.removeOnTrue(ass1, isAssigned, states);
        false = listEmpty(states);
        tvar = selectVarWithMostEqns(states,ass2,mt,-1,-1);
      then
        tvar;
*/

    // if there is a variable unsolvable select it
    case(_,_,_,_,_,_,_,_)
      equation
        unsolvables = getUnsolvableVarsConsiderMatching(BackendVariable.varsSize(vars),mt,ass1,ass2);
        false = listEmpty(unsolvables);
        tvar = listHead(unsolvables);
        if listMember(tvar,tSel_never) then
          Error.addCompilerWarning("There are tearing variables with annotation attribute 'tearingSelect = never'. Use -d=tearingdump and -d=tearingdumpV for more information.");
        end if;
        if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("\nForced selection of Tearing Variable:\n" + UNDERLINE + "\n");
        end if;
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("tVar: " + intString(tvar) + " (unsolvable in omcTearingSelectTearingVar)\n\n");
        end if;
      then
        tvar;

    case(_,_,_,_,_,_,_,_)
      equation
        varsize = BackendVariable.varsSize(vars);
        // variables not assigned yet:
        freeVars = Matching.getUnassigned(varsize,ass1,{});
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("omcTearingSelectTearingVar Candidates(unassigned vars):\n");
          BackendDump.debuglst(freeVars,intString,", ","\n");
        end if;
        (_,freeVars,_) = List.intersection1OnTrue(freeVars,tSel_never,intEq);
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("Candidates without variables with annotation attribute 'never':\n");
          BackendDump.debuglst(freeVars,intString,", ","\n");
        end if;
        size = listLength(freeVars);
        true = intGt(size,0);

        // CALCULATE TEARING-VARIABLE WEIGHTS
        points = arrayCreate(varsize,0);
        // 1st: Points for solvability (see function solvabilityWeights)
        points = List.fold2(freeVars, calcVarWeights,mt,ass2,points);
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("\nPoints after 'calcVarWeights':\n" + stringDelimitList(List.map(arrayList(points),intString),",") + "\n\n");
        end if;
        eqns = Matching.getUnassigned(arrayLength(m),ass2,{});
        // 2nd: 5 points for each equation this variable would causalize
        points = List.fold2(eqns,addEqnWeights,m,ass1,points);
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("Points after 'addEqnWeights':\n" + stringDelimitList(List.map(arrayList(points),intString),",") + "\n\n");
        end if;
        // 3rd: only one-tenth of points for each discrete variable
        points = List.fold1(freeVars,discriminateDiscrete,vars,points);
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("Points after 'discriminateDiscrete':\n" + stringDelimitList(List.map(arrayList(points),intString),",") + "\n\n");
        end if;
        // 4th: Prefer variables with annotation attribute 'tearingSelect=prefer'
        pointsLst = preferAvoidVariables(freeVars, arrayList(points), tSel_prefer, 3.0);
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("Points after preferring variables with attribute 'prefer':\n" + stringDelimitList(List.map(pointsLst,intString),",") + "\n\n");
        end if;
        // 5th: Avoid variables with annotation attribute 'tearingSelect=avoid'
        pointsLst = preferAvoidVariables(freeVars, pointsLst, tSel_avoid, 0.334);
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("Points after discrimination against variables with attribute 'avoid':\n" + stringDelimitList(List.map(pointsLst,intString),",") + "\n\n");
        end if;
        tvar = selectVarWithMostPoints(freeVars,pointsLst);
          // fcall(Flags.TEARING_DUMPVERBOSE,print,"VarsWithMostEqns:\n");
          // fcall(Flags.TEARING_DUMPVERBOSE,BackendDump.debuglst,(freeVars,intString,", ","\n"));
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("tVar: " + intString(tvar) + " (" + intString(listGet(pointsLst,tvar)) + " points)\n\n");
        elseif listMember(tvar,tSel_avoid) then
          Error.addCompilerWarning("The Tearing heuristic has chosen variables with annotation attribute 'tearingSelect = avoid'. Use -d=tearingdump and -d=tearingdumpV for more information.");
        end if;
      then
        tvar;
      else
    equation
        print("omcTearingSelectTearingVar failed because no unmatched var!\n");
      then
        fail();
  end matchcontinue;
end omcTearingSelectTearingVar;


protected function getUnsolvableVarsConsiderMatching
" returns one unsolvable var with respect to the current matching
  author: Frenkel TUD 2012-08"
  input Integer size;
  input BackendDAE.AdjacencyMatrixTEnhanced meT;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output list<Integer> unsolvables = {};
protected
  BackendDAE.AdjacencyMatrixElementEnhanced elem;
  Boolean isUnsolvable;
algorithm
  for index in 1:size loop
    /* unmatched var */
    if intLt(ass1[index],0) then
      elem := meT[index];
      /* consider only unmatched eqns */
      elem := removeMatched(elem,ass2);
      isUnsolvable := unsolvable(elem);
      if isUnsolvable then
        unsolvables := index::unsolvables;
      end if;
    end if;
  end for;
end getUnsolvableVarsConsiderMatching;


protected function removeMatched
" helper function for getUnsolvableVarsConsiderMatching,
  returns only unmatched equations
  author: Frenkel TUD 2012-08"
  input BackendDAE.AdjacencyMatrixElementEnhanced elem;
  input array<Integer> ass2;
  output BackendDAE.AdjacencyMatrixElementEnhanced oAcc = {};
protected
  Integer e;
algorithm
  for el in elem loop
    (e,_,_) := el;
    if intGt(e,0) and intLt(ass2[e],0) then
      oAcc := el::oAcc;
    end if;
  end for;
end removeMatched;


protected function calcVarWeights "function giving points for solvability"
 input Integer v;
 input BackendDAE.AdjacencyMatrixTEnhanced mt;
 input array<Integer> ass2;
 input array<Integer> iPoints;
 output array<Integer> oPoints;
protected
 Integer p;
algorithm
  p := calcSolvabilityWeight(mt[v],ass2);
  oPoints := arrayUpdate(iPoints,v,p);
end calcVarWeights;


protected function calcSolvabilityWeight
"helper function for calcVarWeights, giving points for solvability"
  input BackendDAE.AdjacencyMatrixElementEnhanced inRow;
  input array<Integer> ass2;
  output Integer w;
algorithm
  w := List.fold1(inRow,solvabilityWeightsnoStates,ass2,0);
end calcSolvabilityWeight;


protected function solvabilityWeightsnoStates
"helper function for calcSolvabilityWeight, giving points for solvability
  author: Frenkel TUD 2012-05"
  input tuple<Integer,BackendDAE.Solvability,BackendDAE.Constraints> inTpl;
  input array<Integer> ass;
  input Integer iW;
  output Integer oW;
algorithm
  oW := match(inTpl,ass,iW)
    local
      BackendDAE.Solvability s;
      Integer eq,w;
    case((eq,s,_),_,_)
      guard
        intGt(eq,0) and
        not intGt(ass[eq], 0)
      equation
        w = solvabilityWeights(s);
      then
        intAdd(w,iW);
    else iW;
  end match;
end solvabilityWeightsnoStates;


protected function solvabilityWeights
" helper function for solvabilityWeightsnoStates
  author: Frenkel TUD 2012-05,
  return a integer for the solvability, this function is used
  to calculade weights for variables to select the tearing variable."
  input BackendDAE.Solvability solva;
  output Integer i;
algorithm
  i := match(solva)
    case BackendDAE.SOLVABILITY_SOLVED() then 0;
    case BackendDAE.SOLVABILITY_CONSTONE() then 2;
    case BackendDAE.SOLVABILITY_CONST() then 5;
    case BackendDAE.SOLVABILITY_PARAMETER(b=false) then 0;
    case BackendDAE.SOLVABILITY_PARAMETER(b=true) then 50;
    case BackendDAE.SOLVABILITY_LINEAR(b=false) then 0;
    case BackendDAE.SOLVABILITY_LINEAR(b=true) then 100;
    case BackendDAE.SOLVABILITY_NONLINEAR() then 200;
    case BackendDAE.SOLVABILITY_UNSOLVABLE() then 300;
    else 0;
  end match;
end solvabilityWeights;


protected function addEqnWeights
"function adds five points to variables for each equation it would causalize as tvar"
 input Integer e;
 input BackendDAE.AdjacencyMatrixEnhanced m;
 input array<Integer> ass1;
 input array<Integer> iPoints;
 output array<Integer> oPoints;
algorithm
 oPoints := matchcontinue(e,m,ass1,iPoints)
   local
       Integer v1,v2;
       array<Integer> points;
     case (_,_,_,_)
       equation
         // finds equations with exact two variables (v1,v2)
         ((v1,_,_)::(v2,_,_)::{}) = List.removeOnTrue(ass1, isAssignedSaveEnhanced, m[e]);
         points = arrayUpdate(iPoints,v1,iPoints[v1]+5);
         points = arrayUpdate(iPoints,v2,points[v2]+5);
       then
         points;
     else
       iPoints;
 end matchcontinue;
end addEqnWeights;


protected function isAssignedSaveEnhanced " returns true if var/eqn is already assigned
  author: Frenkel TUD 2012-05"
  input array<Integer> ass;
  input tuple<Integer,BackendDAE.Solvability,BackendDAE.Constraints> inTpl;
  output Boolean outB;
algorithm
  outB := match(ass,inTpl)
    local
      Integer i;
    case (_,(i,_,_)) guard intGt(i,0)
      then
        intGt(ass[i],0);
    else
      true;
  end match;
end isAssignedSaveEnhanced;


protected function discriminateDiscrete " leaves only one-tenth of points for each discrete variable
 author: Frenkel TUD 2012-08"
 input Integer v;
 input BackendDAE.Variables vars;
 input array<Integer> iPoints;
 output array<Integer> oPoints;
protected
 Integer p;
 Boolean b;
 BackendDAE.Var var;
algorithm
  var := BackendVariable.getVarAt(vars, v);
  b := BackendVariable.isVarDiscrete(var);
  p := iPoints[v];
  p := if b then intDiv(p,10) else p;
  oPoints := arrayUpdate(iPoints,v,p);
end discriminateDiscrete;


protected function selectVarWithMostPoints " returns one var with most points
  author: Frenkel TUD 2012-05"
  input list<Integer> vars;
  input list<Integer> points;
  output Integer oVar = -1;
protected
  Integer defp = -1;
  Integer p;
algorithm
  for v in vars loop
    p := listGet(points,v);
    if p > defp then
      defp := p;
      oVar := v;
    end if;
  end for;
end selectVarWithMostPoints;


protected function tearingBFS " function to find maximum matching
  author: Frenkel TUD 2012-05"
  input BackendDAE.AdjacencyMatrixElementEnhanced queue;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input Integer size;
  input array<Integer> ass1;
  input array<Integer> ass2;
  //input array<Integer> columark;
  //input Integer mark;
  input BackendDAE.AdjacencyMatrixElementEnhanced nextQueue;
algorithm
  _ := match(queue,m,mt,mapEqnIncRow,mapIncRowEqn,size,ass1,ass2,nextQueue)
    local
      Integer c,eqnsize,cnonscalar;
      BackendDAE.AdjacencyMatrixElementEnhanced rest,newqueue,rows;
    // if there are no more equations in queue maximum matching is found
    case ({},_,_,_,_,_,_,_,{}) then ();

    // if queue is empty, use next queue
    case ({},_,_,_,_,_,_,_,_)
      equation
        // use only equations from next queue which are not assigned yet
        newqueue = List.removeOnTrue(ass2, isAssignedSaveEnhanced, nextQueue);
        // use linear equations first
        newqueue = sortEqnsSolvable(newqueue,m);
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("Use next Queue!\n");
        end if;
        tearingBFS(newqueue,m,mt,mapEqnIncRow,mapIncRowEqn,size,ass1,ass2,{});
      then
        ();
    case((c,_,_)::rest,_,_,_,_,_,_,_,_)
      equation
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("Queue:\n");
          BackendDump.dumpAdjacencyRowEnhanced(queue);
          print("Process Eqn: " + intString(c) + "\n");
        end if;
        // not assigned variables in equation c:
        rows = List.removeOnTrue(ass1, isAssignedSaveEnhanced, m[c]);
          //arrayUpdate(columark,c,mark);
        // For Equationarrays
        cnonscalar = mapIncRowEqn[c];
        eqnsize = listLength(mapEqnIncRow[cnonscalar]);
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("Eqn Size: " + intString(eqnsize) + "\n");
          // fcall(Flags.TEARING_DUMPVERBOSE, print,"Rows(not assigned variables in eqn " + intString(c) + ":\n" + stringDelimitList(List.mapMap(rows,Util.tuple21,intString),", ") + "\n");
          print("Rows (not assigned variables in eqn " + intString(c) + "):\n");
          BackendDump.dumpAdjacencyRowEnhanced(rows);
          print("\n");
        end if;
        // make assignment and find next equations to get causalized
        newqueue = tearingBFS1(rows,eqnsize,mapEqnIncRow[cnonscalar],mt,ass1,ass2,nextQueue);
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("Next Queue:\n");
          BackendDump.dumpAdjacencyRowEnhanced(newqueue);
          print("\n\n");
        end if;
        tearingBFS(rest,m,mt,mapEqnIncRow,mapIncRowEqn,size,ass1,ass2,newqueue);
      then
        ();
  end match;
end tearingBFS;


protected function sortEqnsSolvable
"  author: Frenkel TUD 2012-10
  moves equations with nonlinear or unsolvable parts to the end"
  input BackendDAE.AdjacencyMatrixElementEnhanced queue;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  output BackendDAE.AdjacencyMatrixElementEnhanced nextQueue;
protected
  BackendDAE.AdjacencyMatrixElementEnhanced qnon,qsolv;
algorithm
  (qnon,qsolv) := List.split1OnTrue(queue,hasnonlinearVars,m);
  nextQueue := listAppend(qsolv,qnon);
end sortEqnsSolvable;


protected function hasnonlinearVars
  input BackendDAE.AdjacencyMatrixElementEnhancedEntry entry;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  output Boolean hasnonlinear;
protected
  Integer r;
  BackendDAE.AdjacencyMatrixElementEnhanced row;
algorithm
  (r,_,_) := entry;
  row := m[r];
  hasnonlinear := hasnonlinearVars1(row);
end hasnonlinearVars;


protected function hasnonlinearVars1
  input BackendDAE.AdjacencyMatrixElementEnhanced row;
  output Boolean hasnonlinear;
algorithm
  hasnonlinear := match(row)
    local
      BackendDAE.AdjacencyMatrixElementEnhanced rest;
    case ( {}) then false;
    case ((_,BackendDAE.SOLVABILITY_NONLINEAR(),_)::_)
      then
        true;
    case (_::rest)
      then
        hasnonlinearVars1(rest);
  end match;
end hasnonlinearVars1;


protected function tearingBFS1 " function checks for possible assignments and calls tearingBFS2
  author: Frenkel TUD 2012-05"
  input BackendDAE.AdjacencyMatrixElementEnhanced rows;
  input Integer size;
  input list<Integer> c;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input array<Integer> ass1;
  input array<Integer> ass2;
  //input array<Integer> columark;
  //input Integer mark;
  input BackendDAE.AdjacencyMatrixElementEnhanced inNextQueue;
  output BackendDAE.AdjacencyMatrixElementEnhanced outNextQueue;
algorithm
  outNextQueue := match(rows,size,c,mt,ass1,ass2,inNextQueue)
    local
    // there is only one variable assignable from this equation and the equation is solvable for this variable
    case (_,_,_,_,_,_,_)
      guard
        intEq(listLength(rows),size) and
        solvableLst(rows)
      equation
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("Assign Eqns: " + stringDelimitList(List.map(c,intString),", ") + "\n");
        end if;
      then
        // make assignment and get next equations
        tearingBFS2(rows,c,mt,ass1,ass2,inNextQueue);
/*    case (_,_,_,_,_,_,_)
      guard
        intEq(listLength(rows),size) and
        not solvableLst(rows);
      equation
          //fcall(Flags.TEARING_DUMPVERBOSE, print,"cannot Assign Var" + intString(r) + " with Eqn " + intString(c) + "\n");
      then
        inNextQueue;
*/
    else inNextQueue;
  end match;
end tearingBFS1;


protected function solvableLst
" returns true if all variables are solvable"
  input BackendDAE.AdjacencyMatrixElementEnhanced rows;
  output Boolean solvable = true;
protected
  BackendDAE.Solvability s;
algorithm
  for r in rows loop
    (_,s,_) := r;
    if not solvable(s) then
      solvable := false;
      return;
    end if;
  end for;
end solvableLst;


protected function solvable
  input BackendDAE.Solvability s;
  output Boolean b;
algorithm
  b := match(s)
    case BackendDAE.SOLVABILITY_SOLVED() then true;
    case BackendDAE.SOLVABILITY_CONSTONE() then true;
    case BackendDAE.SOLVABILITY_CONST(b=b) then b;
    case BackendDAE.SOLVABILITY_PARAMETER(b=b) then (b and not stringEqual(Flags.getConfigString(Flags.TEARING_STRICTNESS), "veryStrict"));
    case BackendDAE.SOLVABILITY_LINEAR() then false;
    case BackendDAE.SOLVABILITY_NONLINEAR() then false;
    case BackendDAE.SOLVABILITY_UNSOLVABLE() then false;
    case BackendDAE.SOLVABILITY_SOLVABLE() then true;
    else false;
  end match;
end solvable;

protected function isEntrySolved
  input BackendDAE.AdjacencyMatrixElementEnhancedEntry entry;
  output Boolean b;
algorithm
  b := match entry
    case (_, BackendDAE.SOLVABILITY_SOLVED(), _) then true;
    case (_, BackendDAE.SOLVABILITY_PARAMETER(b=b), _) algorithm
        Error.addInternalError("SOLVABILITY_PARAMETER is not handled yet. Requires revision.", sourceInfo());
      then (b and not stringEqual(Flags.getConfigString(Flags.TEARING_STRICTNESS), "veryStrict"));
    else false;
  end match;
end isEntrySolved;

protected function isEntrySolvable
  input BackendDAE.AdjacencyMatrixElementEnhancedEntry entry;
  output Boolean b;
protected
  BackendDAE.Solvability s;
algorithm
  b := solvable(Util.tuple32(entry));
end isEntrySolvable;


protected function tearingBFS2 " function to make an assignment and determine the next equations for queue
  author: Frenkel TUD 2012-05"
  input BackendDAE.AdjacencyMatrixElementEnhanced rows;
  input list<Integer> clst;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input array<Integer> ass1;
  input array<Integer> ass2;
  //input array<Integer> columark;
  //input Integer mark;
  input BackendDAE.AdjacencyMatrixElementEnhanced inNextQueue;
  output BackendDAE.AdjacencyMatrixElementEnhanced outNextQueue;
algorithm
  outNextQueue := match(rows,clst,mt,ass1,ass2,inNextQueue)
    local
      Integer r,c;
      list<Integer> ilst;
      BackendDAE.Solvability s;
      BackendDAE.AdjacencyMatrixElementEnhanced rest,vareqns,newqueue;
    case ({},_,_,_,_,_) then inNextQueue;
    case ((r,_,_)::rest,c::ilst,_,_,_,_)
      equation
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
           print("Assignment: Eq " + intString(c) + " - Var " + intString(r) + "\n");
        end if;
        // assign
        arrayUpdate(ass1,r,c);
        arrayUpdate(ass2,c,r);
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("ass1: " + stringDelimitList(List.map(arrayList(ass1),intString),",")+"\n");
          print("ass2: " + stringDelimitList(List.map(arrayList(ass2),intString),",")+"\n");
        end if;
        // not yet assigned equations containing var r
        vareqns = List.removeOnTrue(ass2, isAssignedSaveEnhanced, mt[r]);
        newqueue = listAppend(inNextQueue,vareqns);
      then
        tearingBFS2(rest,ilst,mt,ass1,ass2,newqueue);
  end match;
end tearingBFS2;


protected function omcTearing3 " function to rerun omcTearing2 if there are still unassigned vars
  author: Frenkel TUD 2012-05"
  input list<Integer> unassigned;
  input list<Integer> unsolvables;
  input list<Integer> tSel_always;
  input list<Integer> tSel_prefer;
  input list<Integer> tSel_avoid;
  input list<Integer> tSel_never;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  input BackendDAE.AdjacencyMatrixTEnhanced mt;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input Integer size;
  input BackendDAE.Variables vars;
  input BackendDAE.Shared ishared;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<Integer> columark;
  input Integer mark;
  input list<Integer> inTVars;
  output list<Integer> outTVars;
  output Integer oMark;
algorithm
  (outTVars,oMark) := match(unassigned,unsolvables,tSel_always,tSel_prefer,tSel_avoid,tSel_never,m,mt,mapEqnIncRow,mapIncRowEqn,size,vars,ishared,ass1,ass2,columark,mark,inTVars)
    local
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_) then (inTVars,mark);
    else
      equation
        (outTVars,oMark) = omcTearing2(unsolvables,tSel_always,tSel_prefer,tSel_avoid,tSel_never,m,mt,mapEqnIncRow,mapIncRowEqn,size,vars,ishared,ass1,ass2,columark,mark,inTVars);
      then
        (outTVars,oMark);
  end match;
end omcTearing3;


protected function omcTearing4
" maps indexes back to entire system and creates strong component from tearing information
  author: Frenkel TUD 2012-09"
  input BackendDAE.JacobianType jacType;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.EqSystem subsyst;
  input list<Integer> tvars;
  input list<Integer> residual;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<list<Integer>> othercomps;
  input list<Integer> eindex;
  input list<Integer> vindx;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input array<Integer> columark;
  input Integer mark;
  input Boolean mixedSystem;
  output BackendDAE.StrongComponent ocomp;
  output Boolean outRunMatching;
algorithm
  (ocomp,outRunMatching):=
    matchcontinue (jacType,isyst,ishared,subsyst,tvars,residual,ass1,ass2,othercomps,eindex,vindx,mapEqnIncRow,mapIncRowEqn,columark,mark,mixedSystem)
    local
      list<Integer> ores,residual1,ovars;
      BackendDAE.InnerEquations innerEquations;
      array<Integer> eindxarr,varindxarr;
      Boolean linear;
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("handle torn System\n");
        end if;
        residual1 = List.map1r(residual,arrayGet,mapIncRowEqn);
        residual1 = List.fold2(residual1,uniqueIntLst,mark,columark,{});
        // map indexes back
        eindxarr = listArray(eindex);
        ores = List.map1r(residual1,arrayGet,eindxarr);
        varindxarr = listArray(vindx);
        ovars = List.map1r(tvars,arrayGet,varindxarr);
        innerEquations = omcTearing4_1(othercomps,ass2,mapIncRowEqn,eindxarr,varindxarr,columark,mark);
        linear = BackendDAEUtil.getLinearfromJacType(jacType);
      then
        (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(ovars, ores, innerEquations, BackendDAE.EMPTY_JACOBIAN()), NONE(), linear,mixedSystem),true);
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET({}, {}, {}, BackendDAE.EMPTY_JACOBIAN()), NONE(), false,mixedSystem),false);
  end matchcontinue;
end omcTearing4;


protected function omcTearing4_1
" creates innerEquations for TearingSet
  author: Frenkel TUD 2012-09"
  input list<list<Integer>> othercomps;
  input array<Integer> ass2;
  input array<Integer> mapIncRowEqn;
  input array<Integer> eindxarr;
  input array<Integer> varindxarr;
  input array<Integer> columark;
  input Integer mark;
  output BackendDAE.InnerEquations outInnerEquations;
algorithm
  outInnerEquations := list(
    match x
      local
        list<Integer> vlst,clst,elst;
        Integer e,v,c;

      case {c}
        equation
          e = mapIncRowEqn[c];
          e = eindxarr[e];
          v = ass2[c];
          v = varindxarr[v];
       then
        BackendDAE.INNEREQUATION(eqn=e,vars={v});

      case clst
        equation
          elst = List.map1r(clst,arrayGet,mapIncRowEqn);
          elst = List.fold2(elst,uniqueIntLst,mark,columark,{});
          {e} = elst;
          e = eindxarr[e];
          vlst = List.map1r(clst,arrayGet,ass2);
          vlst = List.map1r(vlst,arrayGet,varindxarr);
       then
        BackendDAE.INNEREQUATION(eqn=e,vars=vlst);
    end match
  for x in othercomps);
end omcTearing4_1;


// ============================================================================
// Section for minimal tearing
//   Tear only the minimal amount of variables from strong components which are
//   all discrete variables.
// ============================================================================
protected function minimalTearing
  "Tears discrete variables from Loops.
   Returns torn system with discrete variables as tearing variables."
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> eindex;
  input list<Integer> vindx;
  input BackendDAE.JacobianType jacType;
  input Boolean mixedSystem;
  output BackendDAE.StrongComponent ocomp;
protected
  Integer size, qidx, vidx;
  array<Integer> nE, nV;
  array<Boolean> varArray, eqArray;
  list<Integer> unsolvedDiscreteVars, algSolvedVars;
  list<Integer> iterationVars = {}, residualequations = {};
  list<BackendDAE.Var> var_lst;
  list<BackendDAE.Equation> eqn_lst;
  BackendDAE.InnerEquations innerEquationsLocalIndex = {}, innerEquations;
  BackendDAE.AdjacencyMatrixEnhanced adjEnh, adjEnhT;
  Boolean linear;
  BackendDAE.EquationArray eqns;
  BackendDAE.EqSystem subsyst;
  BackendDAE.Variables vars;
algorithm
  linear := BackendDAEUtil.getLinearfromJacType(jacType);

try

  // Create a local subsystem to simplify processing. This is not neccessary per-se but is helpful.
  // A little bit of cost is something we can live with for getting a clear view of the system.
  eqn_lst := BackendEquation.getList(eindex,BackendEquation.getEqnsFromEqSystem(isyst));
  eqns := BackendEquation.listEquation(eqn_lst);
  var_lst := List.map1r(vindx, BackendVariable.getVarAt, BackendVariable.daeVars(isyst));
  vars := BackendVariable.listVar1(var_lst);
  subsyst := BackendDAEUtil.createEqSystem(vars, eqns);

  (adjEnh,adjEnhT) := BackendDAEUtil.getAdjacencyMatrixEnhanced(subsyst, ishared, BackendDAEUtil.isInitializationDAE(ishared));

  // print("Minimal Tearing subsystem: \n");
  // BackendDump.printEqSystem(subsyst);

  size := listLength(vindx);
  varArray := arrayCreate(size,true);
  eqArray := arrayCreate(size,true);
  nE := arrayCreate(size,-1);
  nV := arrayCreate(size,-1);

  // find discrete vars. Warn on tearing select always and prefer on discrete vars.
  unsolvedDiscreteVars := findDiscreteWarnTearingSelect(var_lst);
  // print("All discrete Vars: " + stringDelimitList(List.map(unsolvedDiscreteVars,intString),",") + "\n");

  // Look for algorithm equations. If there is an algorithm equation
  // remove all discrete variables solved in it. The algorithm is added as
  // inner equation.
  qidx := 1;
  for eqn in eqn_lst loop
    if BackendEquation.isAlgorithm(eqn) then
      // mark the alg eqn to be ignored for later
      // matching.
      eqArray[qidx] := false;

      algSolvedVars := {};
      for entr in adjEnh[qidx] loop
        // var is solved in this algorithm.
        if isEntrySolved(entr) then
          (vidx,_,_) := entr;
          algSolvedVars := vidx::algSolvedVars;
          unsolvedDiscreteVars := List.deleteMember(unsolvedDiscreteVars,vidx);

          // mark the var to be ignored for later
          // matching.
          varArray[vidx] := false;
        end if;
      end for;

      // create an inner equation for the algorithm.
      innerEquationsLocalIndex := BackendDAE.INNEREQUATION(qidx, algSolvedVars)::innerEquationsLocalIndex;
    end if;
    qidx := qidx + 1;
  end for;
  // print("Non-algorithm-output discrete Vars: " + stringDelimitList(List.map(unsolvedDiscreteVars,intString),",") + "\n");

  // Match the remaining discrete variables
  if not listEmpty(unsolvedDiscreteVars) then
    matchDiscreteVars(unsolvedDiscreteVars, adjEnhT, varArray, eqArray, nE, nV);
    // make inner equations for the matched non-algorithm-output discrete vars.
    (varArray, eqArray, innerEquations) := getTearingSetfromAssign(unsolvedDiscreteVars, nE, varArray, eqArray);

    for iq in innerEquations loop
      innerEquationsLocalIndex := iq::innerEquationsLocalIndex;
    end for;

  end if;

  // Mark all other equations as residual and all other vars
  // as tearing vars.
  // This can be improved a bit to be clearer.
  for i in 1:listLength(eindex) loop
    if eqArray[i] then
      residualequations := i::residualequations;
    end if;

    // This ordering of iteration vars based on the ordering
    // in the normal adjacency matrix seems to cause differences
    // in sumulation time.
    // What is odd is that the order in adj matrix is not really guided
    // by anything. Somehow this seems to be faster for some models.
    // However, we now use the enahnced matrix which can sometimes have
    // the var entries for an equation slightly different order than the normal
    // adj matix.
    // Simulation should not be affected by what order we have here but it is.
    // There is something in later phases that operates according to this order
    // But it should not. This is just random order.
    /*
    for elem in aMatrix[i] loop
      if elem > 0 then
        if varArray[elem] then
          arrayUpdate(varArray,elem,false);
          iterationVars := elem::iterationVars;
        end if;
      end if;
    end for;
    */

    // This performs a bit worse but still better than below.
    /*
    for entry in adjEnh[i] loop
      (vidx,_,_) := entry;
      if vidx > 0 then
        if varArray[vidx] then
          varArray[vidx] := false;
          iterationVars := vidx::iterationVars;
        end if;
      end if;
    end for;
    */

  end for;

  // Mark all other vars as iteration vars.
  // This should be all we need here. The ordering issue needs to be investigated later.
  for i in 1:listLength(vindx) loop
    if varArray[i] then
      iterationVars := i::iterationVars;
    end if;
  end for;

  // dumpTearingSetGlobalIndexes(BackendDAE.TEARINGSET(iterationVars, residualequations, listReverse(innerEquationsLocalIndex), BackendDAE.EMPTY_JACOBIAN()),size," - STRICT SET");

  // Start converting local indeces of variables and equations to their global
  // counterparts (We used a smaller local subsystem for processing the system above.)
  innerEquations := list(
    match ieqn
      case BackendDAE.INNEREQUATION() algorithm
          ieqn.vars := selectFromList_rev(vindx, ieqn.vars);
          ieqn.eqn := listGet(eindex,ieqn.eqn);
       then ieqn;
      else fail();
    end match for ieqn in innerEquationsLocalIndex);

  iterationVars := selectFromList_rev(vindx, iterationVars);
  residualequations := selectFromList_rev(eindex, residualequations);

  // dumpTearingSetGlobalIndexes(BackendDAE.TEARINGSET(iterationVars, residualequations, listReverse(innerEquations), BackendDAE.EMPTY_JACOBIAN()),size," - STRICT SET");

  // Return torn system
  ocomp := BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(listReverse(iterationVars), listReverse(residualequations), listReverse(innerEquations), BackendDAE.EMPTY_JACOBIAN()), NONE(), linear, mixedSystem);
else
  Error.addInternalError("function minimalTearing failed", sourceInfo());
  fail();
end try;
end minimalTearing;


protected function matchDiscreteVars
  "Matches all discrete vars given by inDiscreteVars."
  input list<Integer> inDiscreteVars;
  input BackendDAE.AdjacencyMatrixEnhanced adjEnhT;
  input array<Boolean> varArray;
  input array<Boolean> eqArray;
  input output array<Integer> nE "Equations";
  input output array<Integer> nV "Variables";
protected
  array<Boolean> eqMarker;
algorithm
  try
  for varIdx in inDiscreteVars loop
    eqMarker := arrayCopy(eqArray);
    (eqMarker, nE, nV, true) := pathFound(varIdx, adjEnhT, varArray, eqArray, eqMarker, nE, nV);
  end for;
  else
    Error.addInternalError("function matchDiscreteVars failed", sourceInfo());
    fail();
  end try;
end matchDiscreteVars;

protected function pathFound
  "Tries to find a path in the bipartit graph with respect to solvability for
   matching of discrete variables."
  input Integer varIdx;
  input BackendDAE.AdjacencyMatrixEnhanced adjEnhT;
  input array<Boolean> varArray;
  input array<Boolean> eqArray;
  input output array<Boolean> eqMarker;
  input output array<Integer> nE "Equations";
  input output array<Integer> nV "Variables";
  output Boolean success = false;
protected
  Integer eqIdx;
algorithm
  try
  // Try to find a path in given equation from adjacency matrix
  for entry in adjEnhT[varIdx] loop
    (eqIdx,_,_) := entry;
    if isEntrySolvable(entry) and eqIdx > 0 then

      if eqArray[eqIdx] and nV[eqIdx] == -1 then
          // Path found
          nV[eqIdx] := varIdx;
          nE[varIdx] := eqIdx;
          success := true;
          return;
      end if;

    end if;
  end for;

  // If no path was found mark equation as false and call pathFound
  for entry in adjEnhT[varIdx] loop
    (eqIdx,_,_) := entry;

    if isEntrySolvable(entry) and eqIdx > 0 then
      if eqMarker[eqIdx] then
         eqMarker[eqIdx] := false;
         (eqMarker, nE, nV , success) := pathFound(nV[eqIdx], adjEnhT, varArray, eqArray, eqMarker, nE, nV);
      end if;
    end if;
    if success then
      nV[eqIdx] := varIdx;
      nE[varIdx] := eqIdx;
      return;
    end if;
  end for;

  else
     Error.addInternalError("function pathFound failed", sourceInfo());
     fail();
  end try;
end pathFound;


protected function getTearingSetfromAssign
  "Set equations matched with the discrete vars as inner equations"
  input list<Integer> inDiscreteVars;
  input array<Integer> assign1;
  input output array<Boolean> varArray;
  input output array<Boolean> equationArray;
  output BackendDAE.InnerEquations innerEquations = {};
protected
  Integer eqIdx;
algorithm
  try
    // Add matched discrete equation to inner equations
    for varIdx in inDiscreteVars loop
      arrayUpdate(varArray,varIdx,false);
      eqIdx := assign1[varIdx];
      arrayUpdate(equationArray,eqIdx,false);
      innerEquations := BackendDAE.INNEREQUATION(eqIdx, {varIdx})::innerEquations;
    end for;

  else
    Error.addInternalError("function getTearingSetfromAssign failed", sourceInfo());
    fail();
  end try;
end getTearingSetfromAssign;


// =============================================================================
//
// Tearing from Book of Cellier
//
// =============================================================================

protected function CellierTearing " tearing method based on the method from book of Cellier
author: ptaeuber FHB 2013-2016"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> eindex;
  input list<Integer> vindx;
  input list<Integer> tearingSelect_always;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> ojac;
  input BackendDAE.JacobianType jacType;
  input Boolean mixedSystem;
  input Integer strongComponentIndex;
  output BackendDAE.StrongComponent ocomp;
  output Boolean outRunMatching;
protected
  Integer size, tornsize;
  array<Integer> ass1, ass2, mapIncRowEqn, eqnNonlinPoints;
  array<list<Integer>> mapEqnIncRow;
  list<Integer> OutTVars, residual, residual_coll, order, unsolvables, discreteVars, tSel_always, tSel_prefer, tSel_avoid,tSel_never;
  BackendDAE.InnerEquations innerEquations;
  BackendDAE.EqSystem subsyst;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.AdjacencyMatrix m;
  BackendDAE.AdjacencyMatrix mt;
  BackendDAE.AdjacencyMatrixEnhanced me;
  BackendDAE.AdjacencyMatrixTEnhanced meT;
  BackendDAE.BackendDAEType DAEtype;
  String DAEtypeStr;
  BackendDAE.TearingSet strictTearingSet;
  BackendDAE.StateSets stateSets;
  Option<BackendDAE.TearingSet> casualTearingSet;
  list<BackendDAE.Equation> eqn_lst;
  list<BackendDAE.Var> var_lst;
  Boolean linear,b,noDynamicStateSelection,dynamicTearing;
  String s,modelName;
  constant Boolean debug = false;
algorithm
  linear := BackendDAEUtil.getLinearfromJacType(jacType);
  BackendDAE.EQSYSTEM(stateSets = stateSets) := isyst;
  noDynamicStateSelection := listEmpty(stateSets);
  BackendDAE.SHARED(backendDAEType=DAEtype, info=BackendDAE.EXTRA_INFO(fileNamePrefix=modelName)) := ishared;
  DAEtypeStr := BackendDump.printBackendDAEType2String(DAEtype);

  // check if dynamic tearing is enabled for linear/nonlinear system
  dynamicTearing := match (Config.dynamicTearing(),linear,noDynamicStateSelection,DAEtypeStr,Flags.getConfigBool(Flags.DYNAMIC_TEARING_FOR_INITIALIZATION),Config.simCodeTarget())
    case ("true",_,true,"simulation",_,"C") then true;
    case ("true",_,true,"initialization",true,"C") then true;
    case ("linear",true,true,"simulation",_,"C") then true;
    case ("linear",true,true,"initialization",true,"C") then true;
    case ("nonlinear",false,true,"simulation",_,"C") then true;
    case ("nonlinear",false,true,"initialization",true,"C") then true;
    else false;
  end match;

  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n" + BORDER + "\nBEGINNING of CellierTearing\n\n");
  end if;

  // Generate Subsystem to get the adjacency matrix
  size := listLength(vindx);
  eqn_lst := BackendEquation.getList(eindex,BackendEquation.getEqnsFromEqSystem(isyst));
  eqns := BackendEquation.listEquation(eqn_lst);
  var_lst := List.map1r(vindx, BackendVariable.getVarAt, BackendVariable.daeVars(isyst));
  vars := BackendVariable.listVar1(var_lst);
  subsyst := BackendDAEUtil.createEqSystem(vars, eqns);
  (subsyst,m,mt,_,_) := BackendDAEUtil.getAdjacencyMatrixScalar(subsyst, BackendDAE.NORMAL(),NONE(), BackendDAEUtil.isInitializationDAE(ishared));
  if debug then execStat("Tearing.CellierTearing -> 1"); end if;

  // Delete negative entries from adjacency matrix
  m := Array.map(m,deleteNegativeEntries);
  mt := Array.map(mt,deleteNegativeEntries);

  if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n\n###BEGIN print Strong Component#####################\n(Function:CellierTearing)\n");
    BackendDump.printEqSystem(subsyst);
    print("\n###END print Strong Component#######################\n(Function:CellierTearing)\n\n\n");
  end if;


  // Determine strict tearing set
  // ******************************************

  if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n\nDetermine STRICT TEARING SET\n" + BORDER + BORDER + "\n\n");
  end if;

  // Get advanced adjacency matrix (determine how the variables occur in the equations)
  (me,meT,mapEqnIncRow,mapIncRowEqn) := BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(subsyst,ishared,false);
  if debug then execStat("Tearing.CellierTearing -> 1.5"); end if;

  // Determine unsolvable vars to consider solvability
  unsolvables := getUnsolvableVars(size,meT);

  // Determine a weight for the nonlinearity of each equation
  eqnNonlinPoints := arrayCreate(size, -1);
  getEquationNonlinearityPoints(eqnNonlinPoints, me, size);
  if debug then execStat("Tearing.CellierTearing -> 2"); end if;

  if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nAdjacencyMatrixEnhanced:\n");
    BackendDump.dumpAdjacencyMatrixEnhanced(me);
    print("\nAdjacencyMatrixTransposedEnhanced:\n");
    BackendDump.dumpAdjacencyMatrixTEnhanced(meT);
    print("\neqLinPoints:\n" + stringDelimitList(List.map(arrayList(eqnNonlinPoints),intString),",") + "\n\n");
  end if;

  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("mapEqnIncRow:"); //+ stringDelimitList(List.map(List.flatten(arrayList(mapEqnIncRow)),intString),",") + "\n\n");
    BackendDump.dumpAdjacencyMatrix(mapEqnIncRow);
    print("\nmapIncRowEqn:\n" + stringDelimitList(List.map(arrayList(mapIncRowEqn),intString),",") + "\n\n");
    print("\n\nUNSOLVABLES:\n" + stringDelimitList(List.map(unsolvables,intString),",") + "\n\n");
  end if;

  // Determine discrete vars
  discreteVars := findDiscrete(var_lst);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nDiscrete Vars:\n" + stringDelimitList(List.map(discreteVars,intString),",") + "\n\n");
  end if;

  // Collect variables with annotation attribute 'tearingSelect=always', 'tearingSelect=prefer', 'tearingSelect=avoid' and 'tearingSelect=never'
  (tSel_always,tSel_prefer,tSel_avoid,tSel_never) := tearingSelect(var_lst, tearingSelect_always, DAEtypeStr);
  if not listEmpty(tSel_always) then
    Error.addMessage(Error.USER_TEARING_VARS, {intString(strongComponentIndex), BackendDump.printBackendDAEType2String(DAEtype), BackendDump.dumpMarkedVarList(var_lst, tSel_always)});
  end if;
  if debug then execStat("Tearing.CellierTearing -> 3"); end if;

  // Initialize matching
  ass1 := arrayCreate(size,-1);
  ass2 := arrayCreate(size,-1);
  order := {};
  if debug then execStat("Tearing.CellierTearing -> 3.1"); end if;

  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n" + BORDER + "\nBEGINNING of CellierTearing2\n\n");
  end if;
  (OutTVars, order) := CellierTearing2(false,m,mt,me,meT,ass1,ass2,unsolvables,{},discreteVars,tSel_always,tSel_prefer,tSel_avoid,tSel_never,order,mapEqnIncRow,mapIncRowEqn,eqnNonlinPoints);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nEND of CellierTearing2\n" + BORDER + "\n\n");
  end if;

  // check if tearing makes sense
  tornsize := listLength(OutTVars);
  b := intLt(tornsize, size);

  if debug then execStat("Tearing.CellierTearing -> 3.2"); end if;
  // Unassigned equations are residual equations
  residual := getUnassigned(ass2);
  if debug then execStat("Tearing.CellierTearing -> 3.3"); end if;
  residual_coll := List.map1r(residual,arrayGet,mapIncRowEqn);
  if debug then execStat("Tearing.CellierTearing -> 3.4"); end if;
  residual_coll := List.unique(residual_coll);
  if debug then execStat("Tearing.CellierTearing -> 3.5"); end if;
  // dump results with local indexes
  if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    dumpTearingSetLocalIndexes(OutTVars,residual_coll,order,ass2,size,mapEqnIncRow,vars,eqns," - STRICT SET");
  end if;

  if debug then execStat("Tearing.CellierTearing -> 4"); end if;

  // Convert indexes
  OutTVars := selectFromList_rev(vindx, OutTVars);
  residual := selectFromList_rev(eindex, residual_coll);

  // assign innerEquations:
  innerEquations := assignInnerEquations(order,eindex,vindx,ass2,mapEqnIncRow,NONE());
  if debug then execStat("Tearing.CellierTearing -> 5"); end if;

  // Create BackendDAE.TearingSet for strict set
  strictTearingSet := BackendDAE.TEARINGSET(OutTVars,residual,innerEquations,BackendDAE.EMPTY_JACOBIAN());

  // dump results with global indexes
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    dumpTearingSetGlobalIndexes(strictTearingSet,size," - STRICT SET");
  end if;


  // Determine casual tearing set if dynamic tearing is enabled
  // *****************************************************************

  if dynamicTearing then

    if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("\n\nDetermine CASUAL TEARING SET\n" + BORDER + BORDER + "\n\n");
    end if;

    // Get adjacency matrix again
    (_,m,mt,_,_) := BackendDAEUtil.getAdjacencyMatrixScalar(subsyst, BackendDAE.NORMAL(),NONE(), BackendDAEUtil.isInitializationDAE(ishared));

    // Delete negative entries from adjacency matrix
    m := Array.map(m,deleteNegativeEntries);
    mt := Array.map(mt,deleteNegativeEntries);

    // Get advanced adjacency matrix (determine if the equations are solvable for the variables)
    (me,meT,mapEqnIncRow,mapIncRowEqn) := BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(subsyst,ishared,true);

    // Determine unsolvable vars to consider solvability
    unsolvables := getUnsolvableVars(size,meT);

    if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("\nAdjacencyMatrixEnhanced:\n");
      BackendDump.dumpAdjacencyMatrixEnhanced(me);
      print("\nAdjacencyMatrixTransposedEnhanced:\n");
      BackendDump.dumpAdjacencyMatrixTEnhanced(meT);
      print("\neqLinPoints:\n" + stringDelimitList(List.map(arrayList(eqnNonlinPoints),intString),",") + "\n\n");
    end if;

    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("mapEqnIncRow:"); //+ stringDelimitList(List.map(List.flatten(arrayList(mapEqnIncRow)),intString),",") + "\n\n");
      BackendDump.dumpAdjacencyMatrix(mapEqnIncRow);
      print("\nmapIncRowEqn:\n" + stringDelimitList(List.map(arrayList(mapIncRowEqn),intString),",") + "\n\n");
      print("\n\nUNSOLVABLES:\n" + stringDelimitList(List.map(unsolvables,intString),",") + "\n\n");
      print("\nDiscrete Vars:\n" + stringDelimitList(List.map(discreteVars,intString),",") + "\n\n");
    end if;

    // Initialize matching
    ass1 := arrayCreate(size,-1);
    ass2 := arrayCreate(size,-1);
    order := {};

    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("\n" + BORDER + "\nBEGINNING of CellierTearing2\n\n");
    end if;
    (OutTVars, order) := CellierTearing2(false,m,mt,me,meT,ass1,ass2,unsolvables,{},discreteVars,tSel_always,tSel_prefer,tSel_avoid,tSel_never,order,mapEqnIncRow,mapIncRowEqn,eqnNonlinPoints);
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("\nEND of CellierTearing2\n" + BORDER + "\n\n");
    end if;

    // only continue if dynamic tearing makes sense (casual set < strict set)
    if intLt(listLength(OutTVars), tornsize) then

      // Unassigned equations are residual equations
      residual := getUnassigned(ass2);
      residual_coll := List.map1r(residual,arrayGet,mapIncRowEqn);
      residual_coll := List.unique(residual_coll);

      // dump results with local indexes
      if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
        dumpTearingSetLocalIndexes(OutTVars,residual_coll,order,ass2,size,mapEqnIncRow,vars,eqns," - CASUAL SET");
      end if;

      // Convert indexes
      OutTVars := selectFromList_rev(vindx, OutTVars);
      residual := selectFromList_rev(eindex, residual_coll);

      // assign innerEquations:
      innerEquations := assignInnerEquations(order,eindex,vindx,ass2,mapEqnIncRow,SOME(me));

      // Create BackendDAE.TearingSet for casual set
      casualTearingSet := SOME(BackendDAE.TEARINGSET(OutTVars,residual,innerEquations,BackendDAE.EMPTY_JACOBIAN()));

      // dump results with global indexes
      if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
        dumpTearingSetGlobalIndexes(BackendDAE.TEARINGSET(OutTVars,residual,innerEquations,BackendDAE.EMPTY_JACOBIAN()),size," - CASUAL SET");
      end if;

      if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
        if linear then s:="Linear"; else s:="Nonlinear"; end if;
        print("\nNote:\n=====\n" + s + " dynamic tearing for this strong component in model:\n" + modelName + "\n\n");
      end if;

    else
      if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
        print("\n" + BORDER + "\n* TEARING RESULTS (CASUAL SET):\n*\n* No of equations in strong component: "+intString(size)+"\n");
        print("* No of tVars: "+intString(listLength(OutTVars))+"\n");
        print("*\n* tVars: "+ stringDelimitList(List.map(listReverse(OutTVars),intString),",") + "\n");
        print("*\n* The casual tearing set is not smaller\n* than the strict tearing set and there-\n* fore it is discarded.\n*" + BORDER + "\n");
      end if;

      if not b and not Flags.getConfigBool(Flags.FORCE_TEARING) then
        if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("\nNote:\n=====\nTearing set is discarded because it is not smaller than the original set. Use +forceTearing to prevent this.\n\n");
        end if;
        fail();
      end if;
      casualTearingSet := NONE();
    end if;
    if debug then execStat("Tearing.CellierTearing -> 6"); end if;

  else
    if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("Note:\n=====\nNo dynamic Tearing for this strong component. Check if\n- flag 'dynamicTearing' is set proper\n- strong component does not contain statesets\n- system belongs to simulation\n- SimCode target is 'C'\n\n");
    end if;
    if not b and not Flags.getConfigBool(Flags.FORCE_TEARING) then
        if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
          print("\nNote:\n=====\nTearing set is discarded because it is not smaller than the original set. Use +forceTearing to prevent this.\n\n");
        end if;
        fail();
    end if;
    casualTearingSet := NONE();
    if debug then execStat("Tearing.CellierTearing -> 7"); end if;
  end if;

  // Determine the rest of the information needed for BackendDAE.TORNSYSTEM
  // ***************************************************************************

  ocomp := BackendDAE.TORNSYSTEM(strictTearingSet,casualTearingSet,linear,mixedSystem);
  outRunMatching := true;
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nEND of CellierTearing\n" + BORDER + "\n\n");
  end if;
end CellierTearing;


protected function tearingSelect
 "collects variables with annotation attribute 'tearingSelect=always', 'tearingSelect=prefer', 'tearingSelect=avoid' and 'tearingSelect=never'
  author: ptaeuber FHB 2014-05"
  input list<BackendDAE.Var> var_lstIn;
  input output list<Integer> always;
  input String DAEtypeStr;
  output list<Integer> prefer = {};
  output list<Integer> avoid = {};
  output list<Integer> never = {};
protected
  BackendDAE.Var var;
  Integer index = 1;
  Option<BackendDAE.TearingSelect> ts;
  Boolean preferTVarsWithStartValue;
algorithm
  preferTVarsWithStartValue := Flags.getConfigBool(Flags.PREFER_TVARS_WITH_START_VALUE) and stringEq(DAEtypeStr, "initialization");
  for var in var_lstIn loop
      // Get the value of the variable's tearingSelect attribute.
    BackendDAE.VAR(tearingSelectOption = ts) := var;

      // Add the variable's index to the appropriate list.
      _ := match(ts)
        case SOME(BackendDAE.ALWAYS()) guard not listMember(index, always) algorithm always := index :: always; then ();
        case SOME(BackendDAE.PREFER()) algorithm prefer := index :: prefer; then ();
        case SOME(BackendDAE.AVOID()) algorithm avoid  := index :: avoid;  then ();
        case SOME(BackendDAE.NEVER()) algorithm never  := index :: never;  then ();
        else ();
      end match;

      // Also prefer variables with start value
      if preferTVarsWithStartValue then
        if BackendVariable.varHasStartValue(var) then
          prefer := index :: prefer;
        end if;
      end if;

      index := index + 1;
  end for;

  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nExternal influence on selection of iteration variables by variable annotations (tearingSelect)" + (if preferTVarsWithStartValue then " and preference of variables with start attribute" else "") + ":\n");
    print("Always: " + stringDelimitList(List.map(always, intString), ",") + "\n");
    print("Prefer: " + stringDelimitList(List.map(prefer, intString), ",")+ "\n");
    print("Avoid: " + stringDelimitList(List.map(avoid, intString), ",")+ "\n");
    print("Never: " + stringDelimitList(List.map(never, intString), ",") + "\n\n");
  end if;
end tearingSelect;


public function deleteNegativeEntries
 "deletes all negative entries from adjacency matrix, works with Array.map1, needed for proper Cellier-Tearing
  author: ptaeuber FHB 2014-01"
  input list<Integer> rowIn;
  output list<Integer> rowOut;
algorithm
  rowOut := list(r for r guard r > 0 in rowIn);
end deleteNegativeEntries;


protected function findDiscrete "takes a list of BackendDAE.Var and returns the indexes of the discrete Variables
  author: ptaeuber FHB 2014-01"
  input list<BackendDAE.Var> inVars;
  output list<Integer> discreteVarsOut = {};
protected
  Integer index = 1;
algorithm
  for head in inVars loop
    if BackendVariable.isVarDiscrete(head) then
      discreteVarsOut := index::discreteVarsOut;
    end if;
    index := index + 1;
  end for;
end findDiscrete;

protected function findDiscreteWarnTearingSelect
"mahge: Finds discrete variables in a variable list. This will also warn if the
discrete variable has tearing select annotations. Right now this is used in manadatory
tearing. It should probably used everywhere else as long as we don't have mixed solvers
since we can not chose a discrete variable as a tearing(iteration) variable anyway.
Note: This function returns indices based on the order of the variables in the list."
  input list<BackendDAE.Var> inVars;
  output list<Integer> discreteVarsOut = {};
protected
  Integer index = 1;
algorithm
  for var in inVars loop
    if BackendVariable.isVarDiscrete(var) then
      discreteVarsOut := index::discreteVarsOut;

      _ := match(var.tearingSelectOption)
        case SOME(BackendDAE.ALWAYS()) algorithm
          Error.addSourceMessage(Error.COMPILER_WARNING,{"Minimal Tearing is ignoring tearingSelect=always annotation for discrete variable: "
            + BackendDump.varString(var)},ElementSource.getInfo(var.source));
        then ();
        case SOME(BackendDAE.PREFER()) algorithm
          Error.addSourceMessage(Error.COMPILER_WARNING,{"Minimal Tearing is ignoring tearingSelect=prefer annotation for discrete variable: "
            + BackendDump.varString(var)},ElementSource.getInfo(var.source));
        then ();
        else ();
      end match;

    end if;
    index := index + 1;
  end for;
end findDiscreteWarnTearingSelect;


protected function getEquationNonlinearityPoints
  "Function returns an array with an integer assessment of the nonlinearity
   author: ptaeuber"
  input output array<Integer> eqnNonlinPoints;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input Integer size;
protected
  BackendDAE.AdjacencyMatrixElementEnhanced row;
  Integer sum;
algorithm
  for i in 1:size loop
    row := me[i];
    sum := 0;
    for entry in row loop
      sum := sum + nonlinearityWeight(entry);
    end for;
    eqnNonlinPoints[i] := sum;
  end for;
end getEquationNonlinearityPoints;


protected function nonlinearityWeight
  "Function returns a weight for specific solvability
   author: ptaeuber"
  input BackendDAE.AdjacencyMatrixElementEnhancedEntry entry;
  output Integer weight;
algorithm
  weight := match(entry)
    case(_, BackendDAE.SOLVABILITY_SOLVED(), _) then 0;
    case(_, BackendDAE.SOLVABILITY_CONSTONE(), _) then 2;
    case(_, BackendDAE.SOLVABILITY_CONST(), _) then 5;
    case(_, BackendDAE.SOLVABILITY_PARAMETER(b=true), _) then 10;
    case(_, BackendDAE.SOLVABILITY_PARAMETER(b=false), _) then 20;
    case(_, BackendDAE.SOLVABILITY_LINEAR(b=true), _) then 20;
    case(_, BackendDAE.SOLVABILITY_LINEAR(b=false), _) then 50;
    case(_, BackendDAE.SOLVABILITY_NONLINEAR(), _) then 50;
    case(_, BackendDAE.SOLVABILITY_UNSOLVABLE(), _) then 100;
    else 0;
  end match;
end nonlinearityWeight;


protected function CellierTearing2 " function to call tearing heuristic and matching algorithm
  author: ptaeuber FHB 2013-2015"
  input Boolean inCausal;
  input BackendDAE.AdjacencyMatrix mIn;
  input BackendDAE.AdjacencyMatrixT mtIn;
  input BackendDAE.AdjacencyMatrixEnhanced meIn;
  input BackendDAE.AdjacencyMatrixTEnhanced meTIn;
  input array<Integer> ass1In,ass2In;
  input list<Integer> Unsolvables,tvarsIn,discreteVars,tSel_always,tSel_prefer,tSel_avoid,tSel_never,orderIn;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input array<Integer> eqnNonlinPoints;
  output list<Integer> OutTVars;
  output list<Integer> orderOut;
protected
  constant Boolean debug = false;
algorithm
  if inCausal then
    OutTVars := tvarsIn;
    orderOut := orderIn;
    if debug then execStat("Tearing.CellierTearing2 - done"); end if;
    return;
  end if;
 (OutTVars, orderOut) := match (Unsolvables,tSel_always)
  local
    Integer tvar;
    list<Integer> tvars,unsolvables,tVar_never,tVar_discrete,order;
    Boolean causal;

  // case: There are no unsolvables and no variables with annotation 'tearingSelect = always'
  case ({},{})
    equation
      // select tearing Var
      if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
        print("\n" + BORDER + "\nBEGINNING of selectTearingVar\n\n");
      end if;
      tvar = selectTearingVar(meIn,meTIn,mIn,mtIn,ass1In,ass2In,discreteVars,tSel_prefer,tSel_avoid,tSel_never,mapEqnIncRow,mapIncRowEqn);
      if debug then execStat("Tearing.CellierTearing2 - 1.0"); end if;
      if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
        print("\nEND of selectTearingVar\n" + BORDER + "\n\n");
      end if;

      // mark tvar in ass1In
      arrayUpdate(ass1In,tvar,arrayLength(ass1In)*2);

      // remove tearing var from adjacency matrix and transposed inc matrix
      deleteEntriesFromAdjacencyMatrix(mIn,mtIn,{tvar});
      if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
        print("\n\n###BEGIN print Adjacency Matrix w/o tvar############\n(Function: CellierTearing2)\n");
        BackendDump.dumpAdjacencyMatrix(mIn);
      end if;
      _ = Array.replaceAtWithFill(tvar,{},{},mtIn);
      if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
        BackendDump.dumpAdjacencyMatrixT(mtIn);
        print("\n###END print Adjacency Matrix w/o tvar##############\n(Function: CellierTearing2)\n\n\n");
      end if;

      if debug then execStat("Tearing.CellierTearing2 - 1.1"); end if;
      tvars = tvar::tvarsIn;

      // assign vars to eqs until complete or partially causalisation(and restart algorithm)
      if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
        print("\n" + BORDER + "\nBEGINNING of TarjanMatching\n\n");
      end if;
      (order,causal) = TarjanMatching(mIn,mtIn,meIn,ass1In,ass2In,orderIn,mapEqnIncRow,mapIncRowEqn,eqnNonlinPoints);
      if debug then execStat("Tearing.CellierTearing2 - 1.2"); end if;
      if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
        print("\nEND of TarjanMatching\n" + BORDER + "\n\n");
        print("\n" + BORDER + "\n* TARJAN RESULTS:\n* ass1: " + stringDelimitList(List.map(arrayList(ass1In),intString),",")+"\n");
        print("* ass2: "+stringDelimitList(List.map(arrayList(ass2In),intString),",")+"\n");
        print("* order: "+stringDelimitList(List.map(order,intString),",")+"\n" + BORDER + "\n\n");
      end if;
      if causal and (Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE)) then
          print("\n");
          BackendDump.dumpMatching(ass1In);
          print("\norder: "+stringDelimitList(List.map(order,intString),",")+"\n" + UNDERLINE + "\n\n");
      end if;

      // ascertain if there are new unsolvables now
      unsolvables = getUnsolvableVarsConsiderMatching(arrayLength(meTIn),meTIn,ass1In,ass2In);
      if debug then execStat("Tearing.CellierTearing2 - 1.3"); end if;
      (_,unsolvables,_) = List.intersection1OnTrue(unsolvables,tvars,intEq);

      if debug then execStat("Tearing.CellierTearing2 - 1 done"); end if;

      // repeat until system is causal
      (tvars, order) = CellierTearing2(causal,mIn,mtIn,meIn,meTIn,ass1In,ass2In,unsolvables,tvars,discreteVars,tSel_always,tSel_prefer,tSel_avoid,tSel_never,order,mapEqnIncRow,mapIncRowEqn,eqnNonlinPoints);

   then
     (tvars,order);

  // case: There are unsolvables and/or variables with annotation 'tearingSelect = always'
  else
    equation
      // First choose unsolvables and 'always'-vars as tVars
      tvars = List.unique(listAppend(Unsolvables,tSel_always));
      tVar_never = List.intersectionOnTrue(tSel_never,tvars,intEq);
      tVar_discrete = List.intersectionOnTrue(discreteVars,tvars,intEq);
      if not listEmpty(tVar_never) then
        Error.addCompilerWarning("There are tearing variables with annotation attribute 'tearingSelect = never'. Use -d=tearingdump and -d=tearingdumpV for more information.");
      end if;
      if not listEmpty(tVar_discrete) then
        Error.addCompilerWarning("There are discrete tearing variables because otherwise the system could not have been torn (unsolvables). This may lead to problems during simulation.");
      end if;
      if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
        print("\nForced selection of Tearing Variables:\n" + UNDERLINE + "\nUnsolvables as tVars: "+ stringDelimitList(List.map(Unsolvables,intString),",")+"\n");
        print("Variables with annotation attribute 'always' as tVars: "+ stringDelimitList(List.map(tSel_always,intString),",")+"\n");
      end if;

      // mark tvars in ass1In
      markTVarsOrResiduals(tvars, ass1In);

      // remove tearing var from adjacency matrix and transposed adjacency matrix
      deleteEntriesFromAdjacencyMatrix(mIn, mtIn, tvars);
      deleteRowsFromAdjacencyMatrix(mtIn, tvars);
      if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
        print("\n\n###BEGIN print Adjacency Matrix w/o tvars###########\n(Function: CellierTearing2)\n");
        BackendDump.dumpAdjacencyMatrix(mIn);
        BackendDump.dumpAdjacencyMatrixT(mtIn);
        print("\n###END print Adjacency Matrix w/o tvars#############\n(Function: CellierTearing2)\n\n\n");
        print("\n" + BORDER + "\nBEGINNING of TarjanMatching\n\n");
      end if;

      tvars = listAppend(tvars,tvarsIn) annotation(__OpenModelica_DisableListAppendWarning=true);

      // assign vars to eqs until complete or partially causalisation(and restart algorithm)
      (order,causal) = TarjanMatching(mIn,mtIn,meIn,ass1In,ass2In,orderIn,mapEqnIncRow,mapIncRowEqn,eqnNonlinPoints);
      if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
        print("\nEND of TarjanMatching\n" + BORDER + "\n\n");
        print("\n" + BORDER + "\n* TARJAN RESULTS:\n* ass1: " + stringDelimitList(List.map(arrayList(ass1In),intString),",")+"\n");
        print("* ass2: "+stringDelimitList(List.map(arrayList(ass2In),intString),",")+"\n");
        print("* order: "+stringDelimitList(List.map(order,intString),",")+"\n" + BORDER + "\n\n");
      end if;
      if causal and (Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE)) then
          print("\n");
          BackendDump.dumpMatching(ass1In);
          print("\norder: "+stringDelimitList(List.map(order,intString),",")+"\n" + UNDERLINE + "\n\n");
      end if;

      // ascertain if there are new unsolvables now
      unsolvables = getUnsolvableVarsConsiderMatching(arrayLength(meTIn),meTIn,ass1In,ass2In);
      (_,unsolvables,_) = List.intersection1OnTrue(unsolvables,tvars,intEq);
      if debug then execStat("Tearing.CellierTearing2 - 2"); end if;

      // repeat until system is causal
      (tvars, order) = CellierTearing2(causal,mIn,mtIn,meIn,meTIn,ass1In,ass2In,unsolvables,tvars,discreteVars,{},tSel_prefer,tSel_avoid,tSel_never,order,mapEqnIncRow,mapIncRowEqn,eqnNonlinPoints);

   then
     (tvars, order);
  end match;
end CellierTearing2;


protected function selectTearingVar
 "Selects the next tearing variable referred to one of the following heuristics.
  author: ptaeuber FHB 2013-2015"
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.AdjacencyMatrixTEnhanced meT;
  input BackendDAE.AdjacencyMatrix m;
  input BackendDAE.AdjacencyMatrixT mt;
  input array<Integer> ass1In,ass2In;
  input list<Integer> discreteVars,tSel_prefer,tSel_avoid,tSel_never;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  output Integer OutTVar;
protected
  list<Integer> potentials;
  String heuristic;
  TearingHeuristic tearingHeuristic;
algorithm
  // get the function for the requested tearing heuristic
  heuristic := Config.getTearingHeuristic();
  tearingHeuristic := match heuristic
    case "MC1" then ModifiedCellierHeuristic_1;
    case "MC2" then ModifiedCellierHeuristic_2;
    case "MC11" then ModifiedCellierHeuristic_1_1;
    case "MC21" then ModifiedCellierHeuristic_2_1;
    case "MC12" then ModifiedCellierHeuristic_1_2;
    case "MC22" then ModifiedCellierHeuristic_2_2;
    case "MC13" then ModifiedCellierHeuristic_1_3;
    case "MC23" then ModifiedCellierHeuristic_2_3;
    case "MC231" then ModifiedCellierHeuristic_2_3_1;
    case "MC3" then ModifiedCellierHeuristic_3;
    case "MC4" then ModifiedCellierHeuristic_4;
    else
      equation
        Error.addInternalError("Unknown tearing heuristic: " + heuristic, sourceInfo());
     then fail();
  end match;

  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n" + BORDER + "\nBEGINNING of TearingHeuristic\n\n");
    print("Chosen Heuristic: " + heuristic + "\n\n\n");
  end if;

  // get potential tearing variables
  try
    potentials := tearingHeuristic(m,mt,me,meT,ass1In,ass2In,discreteVars,tSel_prefer,tSel_avoid,tSel_never,mapEqnIncRow,mapIncRowEqn);
    {OutTVar} := potentials;
  else
    print("\nThe selection of a new tearing variable failed.\n");
    Error.addCompilerWarning("Function Tearing.selectTearingVar failed at least once. Use -d=tearingdump or -d=tearingdumpV for more information.");
    fail();
  end try;

  if listMember(OutTVar,tSel_avoid) then
    Error.addCompilerWarning("The Tearing heuristic has chosen variables with annotation attribute 'tearingSelect = avoid'. Use -d=tearingdump and -d=tearingdumpV for more information.");
  end if;
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nEND of TearingHeuristic\n" + BORDER + "\n\n");
  end if;
end selectTearingVar;


protected partial function TearingHeuristic "Heuristic to find a preferably good tearing variable; interface function"
  input BackendDAE.AdjacencyMatrix mIn,mtIn;
  input BackendDAE.AdjacencyMatrixEnhanced meIn;
  input BackendDAE.AdjacencyMatrixTEnhanced metIn;
  input array<Integer> ass1In;
  input array<Integer> ass2In;
  input list<Integer> discreteVars;
  input list<Integer> tSel_prefer;
  input list<Integer> tSel_avoid;
  input list<Integer> tSel_never;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  output list<Integer> potentials={};
end TearingHeuristic;


protected function ModifiedCellierHeuristic_1 " Heuristic to find a preferably good tearing variable [MC1].
author: ptaeuber FHB 2013-2015"
  extends TearingHeuristic;
protected
  Integer edges;
  list<Integer> selectedcols1,selectedrows;
algorithm
  // Cellier heuristic [MC1]

  // 0. get all unassigned variables
  selectedcols1 := getUnassigned(ass1In);

  // 1. choose rows(eqs) with most nonzero entries and write the column indexes(vars) for nonzeros in a list
  selectedcols1 := getVarsOfEqnsWithMostVars(selectedcols1, mIn, mtIn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("1st: " + stringDelimitList(List.map(selectedcols1,intString),",") + "\n");
  end if;
  // Without discrete:
  (_,selectedcols1,_) := List.intersection1OnTrue(selectedcols1,discreteVars,intEq);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("Without Discrete: " + stringDelimitList(List.map(selectedcols1,intString),",") + "\n(Variables in the equation(s) with most Variables)\n\n");
  end if;

  // 2. choose rows (vars) with most nonzero entries and write the indexes in a list
  (edges,selectedcols1) := getVarsOccurringInMostEquations(mtIn, selectedcols1);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("2nd: "+ stringDelimitList(List.map(selectedcols1,intString),",")+"\n(Variables from (1st) with most occurrence in equations (" + intString(edges) +" times))\n\n");
  end if;

  // 3. select the rows(eqs) from mIn which could be causalized by knowing one more Var
  selectedrows := traverseSingleEqnsforAssignable(ass2In,mIn,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print(stringDelimitList(List.map(selectedrows,intString),",")+"\n(Equations which could be causalized by knowing one more Var)\n\n");
  end if;

  // 4. determine which possible Vars causalize most equations considering impossible assignments and write them into potentials
  (potentials,edges) := selectOneMostCausalizingVar(mtIn,selectedcols1, me=meIn,ass1In=ass1In,selEqsSetArray=selectCausalVarsPrepareSelectionSet(selectedrows, arrayLength(ass1In)));
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n3rd: "+ stringDelimitList(List.map(potentials,intString),",")+"\n(Chosen tearing variable. One from (2nd) causalizing most equations [" + intString(edges) +  "])\n\n");
  end if;
end ModifiedCellierHeuristic_1;


protected function ModifiedCellierHeuristic_2 " Heuristic to find a preferably good tearing variable [MC2].
author: ptaeuber FHB 2013-2015"
  extends TearingHeuristic;
protected
  Integer edges;
  list<Integer> varlst,selectedcols1,selectedrows;
algorithm
  // modified Cellier heuristic [MC2]

  // 0. Consider only non-discrete Vars
  varlst := getUnassigned(ass1In);
  (_,selectedcols1,_) := List.intersection1OnTrue(varlst,discreteVars,intEq);

  // 1. choose rows (vars) with most nonzero entries and write the indexes in a list
  (edges,selectedcols1) := getVarsOccurringInMostEquations(mtIn, selectedcols1);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("1st: "+ stringDelimitList(List.map(selectedcols1,intString),",")+"\n(Non-discrete variables with most occurrence in equations (" + intString(edges) +" times))\n\n");
  end if;

  // 2. select the rows(eqs) from mIn which could be causalized by knowing one more Var
  selectedrows := traverseSingleEqnsforAssignable(ass2In,mIn,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print(stringDelimitList(List.map(selectedrows,intString),",")+"\n(Equations which could be causalized by knowing one more Var)\n\n");
  end if;

  // 3. determine which possible Vars causalize most equations considering impossible assignments and write them into potentials
  (potentials,edges) := selectOneMostCausalizingVar(mtIn,selectedcols1, me=meIn,ass1In=ass1In,selEqsSetArray=selectCausalVarsPrepareSelectionSet(selectedrows, arrayLength(ass1In)));
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n2nd: "+ stringDelimitList(List.map(potentials,intString),",")+"\n(Chosen tearing variable. One from (1st) causalizing most equations [" + intString(edges) +  "])\n\n");
  end if;
end ModifiedCellierHeuristic_2;


protected function ModifiedCellierHeuristic_1_1 " Heuristic to find a preferably good tearing variable [MC11].
author: ptaeuber FHB 2013-2015"
  extends TearingHeuristic;
protected
  Integer edges;
  list<Integer> selectedcols1,selectedrows;
algorithm
  // modified Cellier heuristic [MC11]

  // 0. get all unassigned variables
  selectedcols1 := getUnassigned(ass1In);

  // 1. choose rows(eqs) with most nonzero entries and write the column indexes(vars) for nonzeros in a list
  selectedcols1 := getVarsOfEqnsWithMostVars(selectedcols1, mIn, mtIn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("1st: " + stringDelimitList(List.map(selectedcols1,intString),",") + "\n");
  end if;

  // Without discrete:
  (_,selectedcols1,_) := List.intersection1OnTrue(selectedcols1,discreteVars,intEq);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("Without Discrete: " + stringDelimitList(List.map(selectedcols1,intString),",") + "\n(Variables in the equation(s) with most Variables)\n\n");
  end if;

  // 2. choose rows (vars) with most nonzero entries and write the indexes in a list
  (edges,selectedcols1) := getVarsOccurringInMostEquations(mtIn, selectedcols1);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("2nd: "+ stringDelimitList(List.map(selectedcols1,intString),",")+"\n(Variables from (1st) with most occurrence in equations (" + intString(edges) +" times))\n\n");
  end if;

  // 3. select the rows(eqs) from mIn which could be causalized by knowing one more Var
  selectedrows := traverseSingleEqnsforAssignable(ass2In,mIn,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print(stringDelimitList(List.map(selectedrows,intString),",")+"\n(Equations which could be causalized by knowing one more Var)\n\n");
  end if;

  // 4. determine which possible Vars causalize most equations considering impossible assignments and write them into potentials
  (potentials,_) := selectMostCausalizingVars(mtIn,selectedcols1, me=meIn,ass1In=ass1In,selEqsSetArray=selectCausalVarsPrepareSelectionSet(selectedrows, arrayLength(ass1In)));
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n3rd: "+ stringDelimitList(List.map(potentials,intString),",")+"\n(Variables from (2nd) causalizing most equations)\n\n");
  end if;

  // 5. choose vars with the most impossible assignments
  (potentials,edges) := getOneVarWithMostImpAss(potentials,ass2In,metIn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n4th: "+ stringDelimitList(List.map(potentials,intString),",")+"\n(Chosen tearing variable. One from from (3rd) with most incident impossible assignments [" + intString(edges) + "])\n\n");
  end if;
end ModifiedCellierHeuristic_1_1;


protected function ModifiedCellierHeuristic_2_1 " Heuristic to find a preferably good tearing variable [MC21].
author: ptaeuber FHB 2013-2015"
  extends TearingHeuristic;
protected
  Integer edges;
  list<Integer> varlst,selectedcols1,selectedrows;
algorithm
  // modified Cellier heuristic [MC21]

  // 0. Consider only non-discrete Vars
  varlst := getUnassigned(ass1In);
  (_,selectedcols1,_) := List.intersection1OnTrue(varlst,discreteVars,intEq);

  // 1. choose rows (vars) with most nonzero entries and write the indexes in a list
  (edges,selectedcols1) := getVarsOccurringInMostEquations(mtIn, selectedcols1);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("1st: "+ stringDelimitList(List.map(selectedcols1,intString),",")+"\n(Non-discrete variables with most occurrence in equations (" + intString(edges) +" times))\n\n");
  end if;

  // 2. select the rows(eqs) from mIn which could be causalized by knowing one more Var
  selectedrows := traverseSingleEqnsforAssignable(ass2In,mIn,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print(stringDelimitList(List.map(selectedrows,intString),",")+"\n(Equations which could be causalized by knowing one more Var)\n\n");
  end if;

  // 3. determine which possible Vars causalize most equations considering impossible assignments and write them into potentials
  (potentials,_) := selectMostCausalizingVars(mtIn,selectedcols1, me=meIn,ass1In=ass1In,selEqsSetArray=selectCausalVarsPrepareSelectionSet(selectedrows, arrayLength(ass1In)));
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n2nd: "+ stringDelimitList(List.map(potentials,intString),",")+"\n(Variables from (1st) causalizing most equations)\n\n");
  end if;

  // 4. choose vars with the most impossible assignments
  (potentials,edges) := getOneVarWithMostImpAss(potentials,ass2In,metIn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n3rd: "+ stringDelimitList(List.map(potentials,intString),",")+"\n(Chosen tearing variable. One from (2nd) with most incident impossible assignments [" + intString(edges) + "])\n\n");
  end if;
end ModifiedCellierHeuristic_2_1;


protected function ModifiedCellierHeuristic_1_2 " Heuristic to find a preferably good tearing variable [MC12].
author: ptaeuber FHB 2013-2015"
  extends TearingHeuristic;
protected
  Integer edges;
  list<Integer> selectedcols1,selectedrows;
algorithm
  // modified Cellier heuristic [MC12]

  // 0. get all unassigned variables
  selectedcols1 := getUnassigned(ass1In);

  // 1. choose rows(eqs) with most nonzero entries and write the column indexes(vars) for nonzeros in a list
  selectedcols1 := getVarsOfEqnsWithMostVars(selectedcols1, mIn, mtIn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("1st: " + stringDelimitList(List.map(selectedcols1,intString),",") + "\n");
  end if;

  // Without discrete:
  (_,selectedcols1,_) := List.intersection1OnTrue(selectedcols1,discreteVars,intEq);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("Without Discrete: " + stringDelimitList(List.map(selectedcols1,intString),",") + "\n(Variables in the equation(s) with most Variables)\n\n");
  end if;

  // 2. choose rows (vars) with most nonzero entries and write the indexes in a list
  (edges,selectedcols1) := getVarsOccurringInMostEquations(mtIn, selectedcols1);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("2nd: "+ stringDelimitList(List.map(selectedcols1,intString),",")+"\n(Variables from (1st) with most occurrence in equations (" + intString(edges) +" times))\n\n");
  end if;

  // 3. choose vars with the most impossible assignments
  (selectedcols1,_,_) := getAllVarsWithMostImpAss(selectedcols1,ass2In,metIn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n3rd: "+ stringDelimitList(List.map(selectedcols1,intString),",")+"\n(Variables from (2nd) with most incident impossible assignments)\n\n");
  end if;

  // 4. select the rows(eqs) from mIn which could be causalized by knowing one more Var
  selectedrows := traverseSingleEqnsforAssignable(ass2In,mIn,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print(stringDelimitList(List.map(selectedrows,intString),",")+"\n(Equations which could be causalized by knowing one more Var)\n\n");
  end if;

  // 5. determine which possible Vars causalize most equations considering impossible assignments and write them into potentials
  (potentials,edges) := selectOneMostCausalizingVar(mtIn,selectedcols1, me=meIn,ass1In=ass1In,selEqsSetArray=selectCausalVarsPrepareSelectionSet(selectedrows, arrayLength(ass1In)));
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n4th: "+ stringDelimitList(List.map(potentials,intString),",")+"\n(Chosen tearing variable.One from (3rd) causalizing most equations [" + intString(edges) +  "])\n\n");
  end if;
end ModifiedCellierHeuristic_1_2;


protected function ModifiedCellierHeuristic_2_2 " Heuristic to find a preferably good tearing variable [MC22].
author: ptaeuber FHB 2013-2015"
  extends TearingHeuristic;
protected
  Integer edges;
  list<Integer> varlst,selectedcols1,selectedrows;
algorithm
  // modified Cellier heuristic [MC22]

  // 0. Consider only non-discrete Vars
  varlst := getUnassigned(ass1In);
  (_,selectedcols1,_) := List.intersection1OnTrue(varlst,discreteVars,intEq);

  // 1. choose rows (vars) with most nonzero entries and write the indexes in a list
  (edges,selectedcols1) := getVarsOccurringInMostEquations(mtIn, selectedcols1);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("1st: "+ stringDelimitList(List.map(selectedcols1,intString),",")+"\n(Non-discrete variables with most occurrence in equations (" + intString(edges) +" times))\n\n");
  end if;

  // 2. choose vars with the most impossible assignments
  (selectedcols1,_,_) := getAllVarsWithMostImpAss(selectedcols1,ass2In,metIn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n2nd: "+ stringDelimitList(List.map(selectedcols1,intString),",")+"\n(Variables from (1st) with most incident impossible assignments)\n\n");
  end if;

  // 3. select the rows(eqs) from mIn which could be causalized by knowing one more Var
  selectedrows := traverseSingleEqnsforAssignable(ass2In,mIn,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print(stringDelimitList(List.map(selectedrows,intString),",")+"\n(Equations which could be causalized by knowing one more Var)\n\n");
  end if;

  // 4. determine which possible Vars causalize most equations considering impossible assignments and write them into potentials
  (potentials,edges) := selectOneMostCausalizingVar(mtIn,selectedcols1, me=meIn,ass1In=ass1In,selEqsSetArray=selectCausalVarsPrepareSelectionSet(selectedrows, arrayLength(ass1In)));
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n3rd: "+ stringDelimitList(List.map(potentials,intString),",")+"\n(Chosen tearing variable. One from (2nd) causalizing most equations [" + intString(edges) +  "])\n\n");
  end if;
end ModifiedCellierHeuristic_2_2;


protected function ModifiedCellierHeuristic_1_3 " Heuristic to find a preferably good tearing variable [MC13].
author: ptaeuber FHB 2013-2015"
  extends TearingHeuristic;
protected
  Integer edges,maxPoints;
  list<Integer> selectedcols1,selectedrows,points,counts1,counts2;
algorithm
  // Cellier heuristic [MC13]

  // 0. get all unassigned variables
  selectedcols1 := getUnassigned(ass1In);

  // 1. choose rows(eqs) with most nonzero entries and write the column indexes(vars) for nonzeros in a list
  selectedcols1 := getVarsOfEqnsWithMostVars(selectedcols1, mIn, mtIn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("1st: " + stringDelimitList(List.map(selectedcols1,intString),",") + "\n");
  end if;

  // Without discrete:
  (_,selectedcols1,_) := List.intersection1OnTrue(selectedcols1,discreteVars,intEq);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("Without Discrete: " + stringDelimitList(List.map(selectedcols1,intString),",") + "\n(Variables in the equation(s) with most Variables)\n\n");
  end if;

  // 2. choose rows (vars) with most nonzero entries and write the indexes in a list
  (edges,selectedcols1) := getVarsOccurringInMostEquations(mtIn, selectedcols1);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("2nd: "+ stringDelimitList(List.map(selectedcols1,intString),",")+"\n(Variables from (1st) with most occurrence in equations (" + intString(edges) +" times))\n\n");
  end if;

  // 3. select the rows(eqs) from mIn which could be causalized by knowing one more Var
  selectedrows := traverseSingleEqnsforAssignable(ass2In,mIn,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print(stringDelimitList(List.map(selectedrows,intString),",")+"\n(Equations which could be causalized by knowing one more Var)\n\n");
  end if;

  // 4. determine for each variable the number of equations it could causalize considering impossible assignments and save them in counts1
  (_,counts1) := selectMostCausalizingVars(mtIn,selectedcols1, me=meIn,ass1In=ass1In,selEqsSetArray=selectCausalVarsPrepareSelectionSet(selectedrows, arrayLength(ass1In)));
  counts1 := listReverse(counts1);

  // 5. determine for each variable the number of impossible assignments and save them in counts2
  (_,counts2,_) := getAllVarsWithMostImpAss(selectedcols1,ass2In,metIn);

  // 6. Calculate the sum of number of impossible assignments and causalizable equations for each variable and save them in points
  points := List.threadMap(counts1,counts2,intAdd);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nPoints: "+ stringDelimitList(List.map(points,intString),",")+"\n(Sum of impossible assignments and causalizable equations)\n");
  end if;

  // 7. Choose vars with most points as potentials (tearing variable)
  (potentials, maxPoints) := getOneVarWithMostPoints(selectedcols1, points);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n3rd: "+ stringDelimitList(List.map(potentials,intString),",")+"\n(Chosen tearing variable. One from (2nd) with most points [" + intString(maxPoints) + "])\n\n");
  end if;
end ModifiedCellierHeuristic_1_3;


protected function ModifiedCellierHeuristic_2_3 " Heuristic to find a preferably good tearing variable [MC23].
author: ptaeuber FHB 2013-2015"
  extends TearingHeuristic;
protected
  Integer edges,maxPoints;
  list<Integer> varlst,selectedcols1,selectedrows,points,counts1,counts2;
algorithm
  // Cellier heuristic [MC23]

  // 0. Consider only non-discrete Vars
  varlst := getUnassigned(ass1In);
  (_,selectedcols1,_) := List.intersection1OnTrue(varlst,discreteVars,intEq);

  // 1. choose rows (vars) with most nonzero entries and write the indexes in a list
  (edges,selectedcols1) := getVarsOccurringInMostEquations(mtIn, selectedcols1);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("1st: "+ stringDelimitList(List.map(selectedcols1,intString),",")+"\n(Non-discrete variables with most occurrence in equations (" + intString(edges) +" times))\n\n");
  end if;

  // 2. select the rows(eqs) from mIn which could be causalized by knowing one more Var
  selectedrows := traverseSingleEqnsforAssignable(ass2In,mIn,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print(stringDelimitList(List.map(selectedrows,intString),",")+"\n(Equations which could be causalized by knowing one more Var)\n\n");
  end if;

  // 3. determine for each variable the number of equations it could causalize considering impossible assignments and save them in counts1
  (_,counts1) := selectMostCausalizingVars(mtIn,selectedcols1, me=meIn,ass1In=ass1In,selEqsSetArray=selectCausalVarsPrepareSelectionSet(selectedrows, arrayLength(ass1In)));
  counts1 := listReverse(counts1);

  // 4. determine for each variable the number of impossible assignments and save them in counts2
  (_,counts2,_) := getAllVarsWithMostImpAss(selectedcols1,ass2In,metIn);

  // 5. Calculate the sum of number of impossible assignments and causalizable equations for each variable and save them in points
  points := List.threadMap(counts1,counts2,intAdd);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nPoints: "+ stringDelimitList(List.map(points,intString),",")+"\n(Sum of impossible assignments and causalizable equations)\n");
  end if;

  // 6. Choose vars with most points as potentials (tearing variable)
  (potentials, maxPoints) := getOneVarWithMostPoints(selectedcols1, points);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n2nd: "+ stringDelimitList(List.map(potentials,intString),",")+"\n(Chosen tearing variable. One from (1st) with most points [" + intString(maxPoints) + "])\n\n");
  end if;
end ModifiedCellierHeuristic_2_3;


protected function ModifiedCellierHeuristic_2_3_1 " Heuristic to find a preferably good tearing variable [MC231].
author: ptaeuber FHB 2013-2015"
  extends TearingHeuristic;
protected
  Integer edges,potpoints1,potpoints2;
  list<Integer> varlst,selectedcols0,selectedcols1,selectedrows,potentials1,potentials2,counts1,counts2,points1,points2;
algorithm
  // modified Cellier heuristic [MC231]

  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("Start round 1:\n==============\n\n");
  end if;

  // 0. Consider only non-discrete Vars
  varlst := getUnassigned(ass1In);
  (_,selectedcols0,_) := List.intersection1OnTrue(varlst,discreteVars,intEq);

  // 1. choose rows (vars) with most nonzero entries and write the indexes in a list
  (edges,selectedcols1) := getVarsOccurringInMostEquations(mtIn, selectedcols0);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("1st: "+ stringDelimitList(List.map(selectedcols1,intString),",")+"\n(Non-discrete variables with most occurrence in equations (" + intString(edges) +" times))\n\n");
  end if;

  // 2. select the rows(eqs) from mIn which could be causalized by knowing one more Var
  selectedrows := traverseSingleEqnsforAssignable(ass2In,mIn,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print(stringDelimitList(List.map(selectedrows,intString),",")+"\n(Equations which could be causalized by knowing one more Var)\n\n");
  end if;

  // 3. determine for each variable the number of equations it could causalize considering impossible assignments and save them in counts1
  (_,counts1) := selectMostCausalizingVars(mtIn,selectedcols1, me=meIn,ass1In=ass1In,selEqsSetArray=selectCausalVarsPrepareSelectionSet(selectedrows, arrayLength(ass1In)));
  counts1 := listReverse(counts1);

  // 4. determine for each variable the number of impossible assignments and save them in counts2
  (_,counts2,_) := getAllVarsWithMostImpAss(selectedcols1,ass2In,metIn);

  // 5. Calculate the sum of number of impossible assignments and causalizable equations for each variable and save them in points1
  points1 := List.threadMap(counts1,counts2,intAdd);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nPoints: "+ stringDelimitList(List.map(points1,intString),",")+"\n(Sum of impossible assignments and causalizable equations)\n");
  end if;

  // 6. Choose vars with most points as potentials (tearing variable)
  (potentials1, potpoints1) := getOneVarWithMostPoints(selectedcols1, points1);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n2nd: "+ stringDelimitList(List.map(potentials1,intString),",")+"\n(Chosen tearing variable. One from (1st) with most points (" + intString(potpoints1) + " points))\n\n");
  end if;

  // 7. choose non-discrete vars with edges-1 edges and write the indexes in a list
  selectedcols1 := findNEntries(mtIn,selectedcols0, edges-1);

  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nStart round 2:\n==============\n\n1st: "+ stringDelimitList(List.map(selectedcols1,intString),",")+"\n(Variables with occurrence in " + intString(edges-1) + " equations)\n\n" + stringDelimitList(List.map(selectedrows,intString),",")+"\n(Equations which could be causalized by knowing one more Var)\n\n");
  end if;
  if listEmpty(selectedcols1) then
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("Second set is empty.");
    end if;
    potentials := potentials1;
    potpoints2 := 0;
  else
      // 9. determine for each variable the number of equations it could causalize considering impossible assignments and save them in counts1
    (_,counts1) := selectMostCausalizingVars(mtIn,selectedcols1, me=meIn,ass1In=ass1In,selEqsSetArray=selectCausalVarsPrepareSelectionSet(selectedrows, arrayLength(ass1In)));
    counts1 := listReverse(counts1);

    // 10. determine for each variable the number of impossible assignments and save them in counts2
    (_,counts2,_) := getAllVarsWithMostImpAss(selectedcols1,ass2In,metIn);

    // 11. Calculate the sum of number of impossible assignments and causalizable equations for each variable and save them in points2
    points2 := List.threadMap(counts1,counts2,intAdd);
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("\nPoints: "+ stringDelimitList(List.map(points2,intString),",")+"\n(Sum of impossible assignments and causalizable equations)\n");
    end if;

    // 12. Choose vars with most points as potentials (tearing variable)
    (potentials2, potpoints2) := getOneVarWithMostPoints(selectedcols1, points2);
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("\n2nd: "+ stringDelimitList(List.map(potentials2,intString),",")+"\n(Chosen tearing variable. One from (1st) with most points (" + intString(potpoints2) + " points))\n\n");
    end if;

    // 13. choose potentials-set with most points
    potentials := if intGe(potpoints1,potpoints2) then potentials1 else potentials2;
  end if;
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n=====================\nChosen tearing variable: " + stringDelimitList(List.map(potentials,intString),",") + "\n=====================\n(from round 1: " + boolString(intGe(potpoints1,potpoints2)) + ")\n\n");
  end if;
end ModifiedCellierHeuristic_2_3_1;


protected function ModifiedCellierHeuristic_3 " Heuristic to find a preferably good tearing variable [MC3].
author: ptaeuber FHB 2013-2015"
  extends TearingHeuristic;
protected
  Integer edges,maxPoints;
  list<Integer> potentialTVars,potentialTVars2,bestPotentialTVars,causEq,points,counts1,counts2;
  list<list<Integer>> varsWithPoints;
  constant Boolean debug = false;
algorithm
  // Cellier heuristic [MC3]
  if debug then execStat("TEARINGHEURISTIC0"); end if;

  // 1. Determine the equations with size(equation)+1 variables and save them in causEq
  // **********************************************************************************
  causEq := traverseSingleEqnsforAssignable(ass2In,mIn,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("1st: "+ stringDelimitList(List.map(causEq,intString),",")+"\n(Equations which could be causalized by knowing one more variable)\n\n");
  end if;
  if debug then execStat("TEARINGHEURISTIC1"); end if;

  // 2. Get all unassigned variables as a first selection of potential tearing variables
  // ***********************************************************************************
  potentialTVars := getUnassigned(ass1In);

  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("2nd: "+ stringDelimitList(List.map(potentialTVars,intString),",")+"\n(All unassigned variables)\n\n");
  end if;
  if debug then execStat("TEARINGHEURISTIC2"); end if;

  // 3. Remove variables we don't want as tearing variables
  // ******************************************************
  // Remove variables with attribute tearingSelect=never
  (_,potentialTVars,_) := List.intersection1OnTrue(potentialTVars,tSel_never,intEq);
  if listEmpty(potentialTVars) then
    Error.addCompilerError("It is not possible to select a new tearing variable, because all left variables have the attribute tearingSelect=never");
    return;
  end if;

  // Remove discrete variables
  (_,potentialTVars2,_) := List.intersection1OnTrue(potentialTVars,discreteVars,intEq);

  // Only discrete potentials, then allow discrete tearing variables
  if listEmpty(potentialTVars2) then
    potentialTVars2 := potentialTVars;
    Error.addCompilerWarning("The tearing heuristic was not able to avoid discrete iteration variables because otherwise the system could not have been torn. This may lead to problems during simulation.");
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("3rd: "+ stringDelimitList(List.map(potentialTVars2,intString),",")+"\n(All unassigned variables without attribute 'never' (only discrete variables left))\n\n");
    end if;
  else
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("3rd: "+ stringDelimitList(List.map(potentialTVars2,intString),",")+"\n(All non-discrete variables from (2nd) without attribute 'never')\n\n");
    end if;
  end if;
  if debug then execStat("TEARINGHEURISTIC3"); end if;

  // 4. Assess the potential tearing variables
  // *****************************************
  // 4.1 Determine for each variable the number of equations it could causalize considering impossible assignments and save them in counts1
  (potentialTVars,counts1) := selectCausalizingVars(mtIn,potentialTVars2, me=meIn,ass1In=ass1In,selEqsSetArray=selectCausalVarsPrepareSelectionSet(causEq, arrayLength(ass1In)));

  // If none of the variables is able to causalize an equation in the next step, use the previous selection
  if listEmpty(potentialTVars) then
    potentialTVars := potentialTVars2;
    counts1 := List.fill(0, listLength(potentialTVars2));
  end if;
  if debug then execStat("TEARINGHEURISTIC4_1"); end if;

  // 4.2 Determine for each variable the number of impossible assignments and save them in counts2
  (_,counts2,_) := getAllVarsWithMostImpAss(potentialTVars,ass2In,metIn);
  if debug then execStat("TEARINGHEURISTIC4_2"); end if;

  // 4.3 Calculate the sum of number of impossible assignments and causalizable equations for each variable and save them in points
  points := List.threadMap(counts1,counts2,intAdd);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n4th (Points): "+ stringDelimitList(List.map(listReverse(points),intString),",")+"\n(Sum of impossible assignments and causalizable equations)\n");
  end if;
  if debug then execStat("TEARINGHEURISTIC4_3"); end if;

  // 4.4 Prefer variables with annotation attribute 'tearingSelect=prefer'
  if not listEmpty(tSel_prefer) then
    points := preferAvoidVariables(potentialTVars, points, tSel_prefer, 3.0);
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("    (Points): "+ stringDelimitList(List.map(points,intString),",")+"\n(Points after preferring variables with attribute 'prefer')\n");
    end if;
  end if;
  if debug then execStat("TEARINGHEURISTIC4_4"); end if;

  // 4.5 Avoid variables with annotation attribute 'tearingSelect=avoid'
  if not listEmpty(tSel_avoid) then
    points := preferAvoidVariables(potentialTVars, points, tSel_avoid, 0.334);
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("    (Points): "+ stringDelimitList(List.map(points,intString),",")+"\n(Points after discrimination against variables with attribute 'avoid')\n");
    end if;
  end if;
  if debug then execStat("TEARINGHEURISTIC4_5"); end if;

  // 5. Choose vars with most points and save them in bestPotentialTVars
  // *******************************************************************
  (bestPotentialTVars, maxPoints) := getAllVarsWithMostPoints(potentialTVars, points);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n5th: "+ stringDelimitList(List.map(bestPotentialTVars,intString),",")+"\n(Variables from (3rd) with most points [" + intString(maxPoints) + "])\n\n");
  end if;
  if debug then execStat("TEARINGHEURISTIC5"); end if;

  // 6. Choose one var with most occurrence in equations as potentials (tearing variable)
  // ************************************************************************************
  (edges,potentials) := getVarOccurringInMostEquations(mtIn,bestPotentialTVars);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("6th: "+ stringDelimitList(List.map(potentials,intString),",")+"\n(Chosen tearing variable. One from (5th) with most occurrence in equations (" + intString(edges) +" times))\n\n");
  end if;
  if debug then execStat("TEARINGHEURISTIC6"); end if;
end ModifiedCellierHeuristic_3;


protected function ModifiedCellierHeuristic_4 " Heuristic to find a preferably good tearing variable [MC4].
author: ptaeuber FHB 2013-2015"
  extends TearingHeuristic;
protected
  Integer edges;
  list<Integer> potentials1,potentials2,potentials3,potentials4,potentials5,potentials6,potentials7,potentials8,potentials9,potentials10,selectedvars,count;
algorithm
  // Cellier heuristic [MC4]

  // 1. Use heuristics MC1, MC2, MC11, MC21, MC12, MC22, MC13, MC23, MC231, MC3 to determine their potential sets
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("Heuristic uses all modified Cellier-Heuristics\n\nHeuristic [MC1]\n"+ BORDER +"\n");
  end if;
  potentials1 := ModifiedCellierHeuristic_1(mIn,mtIn,meIn,metIn,ass1In,ass2In,discreteVars,tSel_prefer,tSel_avoid,tSel_never,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n\nHeuristic [MC2]\n"+ BORDER +"\n");
  end if;
  potentials2 := ModifiedCellierHeuristic_2(mIn,mtIn,meIn,metIn,ass1In,ass2In,discreteVars,tSel_prefer,tSel_avoid,tSel_never,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n\nHeuristic [MC11]\n"+ BORDER +"\n");
  end if;
  potentials3 := ModifiedCellierHeuristic_1_1(mIn,mtIn,meIn,metIn,ass1In,ass2In,discreteVars,tSel_prefer,tSel_avoid,tSel_never,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n\nHeuristic [MC21]\n"+ BORDER +"\n");
  end if;
  potentials4 := ModifiedCellierHeuristic_2_1(mIn,mtIn,meIn,metIn,ass1In,ass2In,discreteVars,tSel_prefer,tSel_avoid,tSel_never,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n\nHeuristic [MC12]\n"+ BORDER +"\n");
  end if;
  potentials5 := ModifiedCellierHeuristic_1_2(mIn,mtIn,meIn,metIn,ass1In,ass2In,discreteVars,tSel_prefer,tSel_avoid,tSel_never,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n\nHeuristic [MC22]\n"+ BORDER +"\n");
  end if;
  potentials6 := ModifiedCellierHeuristic_2_2(mIn,mtIn,meIn,metIn,ass1In,ass2In,discreteVars,tSel_prefer,tSel_avoid,tSel_never,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n\nHeuristic [MC13]\n"+ BORDER +"\n");
  end if;
  potentials7 := ModifiedCellierHeuristic_1_3(mIn,mtIn,meIn,metIn,ass1In,ass2In,discreteVars,tSel_prefer,tSel_avoid,tSel_never,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n\nHeuristic [MC23]\n"+ BORDER +"\n");
  end if;
  potentials8 := ModifiedCellierHeuristic_2_3(mIn,mtIn,meIn,metIn,ass1In,ass2In,discreteVars,tSel_prefer,tSel_avoid,tSel_never,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n\nHeuristic [MC231]\n"+ BORDER +"\n");
  end if;
  potentials9 := ModifiedCellierHeuristic_2_3_1(mIn,mtIn,meIn,metIn,ass1In,ass2In,discreteVars,tSel_prefer,tSel_avoid,tSel_never,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n\nHeuristic [MC3]\n"+ BORDER +"\n");
  end if;
  potentials10 := ModifiedCellierHeuristic_3(mIn,mtIn,meIn,metIn,ass1In,ass2In,discreteVars,tSel_prefer,tSel_avoid,tSel_never,mapEqnIncRow,mapIncRowEqn);
  if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print(BORDER + "\n\nSynopsis:\n=========\n[MC1]: " + stringDelimitList(List.map(potentials1,intString),",")+"\n");
    print("[MC2]: " + stringDelimitList(List.map(potentials2,intString),",")+"\n");
    print("[MC11]: " + stringDelimitList(List.map(potentials3,intString),",")+"\n");
    print("[MC21]: " + stringDelimitList(List.map(potentials4,intString),",")+"\n");
    print("[MC12]: " + stringDelimitList(List.map(potentials5,intString),",")+"\n");
    print("[MC22]: " + stringDelimitList(List.map(potentials6,intString),",")+"\n");
    print("[MC13]: " + stringDelimitList(List.map(potentials7,intString),",")+"\n");
    print("[MC23]: " + stringDelimitList(List.map(potentials8,intString),",")+"\n");
    print("[MC231]: " + stringDelimitList(List.map(potentials9,intString),",")+"\n");
    print("[MC3]: " + stringDelimitList(List.map(potentials10,intString),",")+"\n\n");
  end if;

  // 2. Collect all variables from different potential-sets in one list
  selectedvars := listAppend(potentials1,listAppend(potentials2,listAppend(potentials3,listAppend(potentials4,listAppend(potentials5,listAppend(potentials6,listAppend(potentials7,listAppend(potentials8,listAppend(potentials9,potentials10)))))))));
  if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("1st: "+ stringDelimitList(List.map(selectedvars,intString),",")+"\n(All potentials)\n\n");
  end if;

  // 3. determine potentials with most occurrence in potential sets
 (count,selectedvars,_) := countMultiples(arrayCreate(1,selectedvars));
  if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("2nd: "+ stringDelimitList(List.map(selectedvars,intString),",")+"\n(Variables from (1st) occurring in most potential-sets (" + stringDelimitList(List.map(count,intString),",") + " sets))\n\n");
  end if;

  // 4. Choose vars with most occurrence in equations as potentials
  (edges,potentials) := getVarOccurringInMostEquations(mtIn, selectedvars);

  if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("3rd: "+ stringDelimitList(List.map(potentials,intString),",")+"\n(Chosen tearing variable. One from from (2nd) with most occurrence in equations (" + intString(edges) +" times))\n\n\n");
  end if;
end ModifiedCellierHeuristic_4;


protected function preferAvoidVariables
 "multiplies points of variables with annotation attribute 'tearingSelect=prefer' or 'tearingSelect=avoid' with factor
  author: ptaeuber FHB 2014-05"
  input list<Integer> varsIn;
  input output list<Integer> points;
  input list<Integer> preferAvoidIn;
  input Real factor;
protected
  Integer preferAvoidVar, pos;
algorithm
  for preferAvoidVar in preferAvoidIn loop
    try
      pos := List.position(preferAvoidVar,varsIn);
      points := List.set(points,pos,realInt(realMul(factor,intReal(listGet(points,pos)))));
    else
    end try;
  end for;
end preferAvoidVariables;


protected function selectCausalVarsPrepareSelectionSet
  "selectMostCausalizingVars takes as input an array ass1In. selEqs and each row
  has indexes into ass1In and we need to intersect selEqs with each row.
  This prepares a set by making an array of all possible indexes and
  marking the ones that exist in selEqs."
  input list<Integer> selEqs;
  input Integer ass1In_size;
  output array<Boolean> selEqsSetArray;
algorithm
  selEqsSetArray := arrayCreate(ass1In_size, false);
  for e in selEqs loop
    arrayUpdate(selEqsSetArray, e, true);
  end for;
end selectCausalVarsPrepareSelectionSet;


protected function selectMostCausalizingVars
" determines the variables causalizing the most equations in the next step.
  author: ptaeuber FHB 2013-2015"
  input BackendDAE.AdjacencyMatrix inMt;
  input list<Integer> selVars;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input array<Integer> ass1In;
  input array<Boolean> selEqsSetArray;
  output list<Integer> cVars = {};
  output list<Integer> counts = {};
protected
  list<Integer> row;
  Integer size,num = 0;
algorithm
  for var in selVars loop
    row := arrayGet(inMt, var);
    arrayUpdate(ass1In,var,1);
    size := 0;
    for i in row loop
      if arrayGet(selEqsSetArray,i) then
        size := sizeOfAssignable(i,me,ass1In,size);
      end if;
    end for;
    arrayUpdate(ass1In,var,-1);

    if size < num then
      counts := size::counts;
    elseif size == num then
      cVars := var::cVars;
      counts := size::counts;
    else
      cVars := {var};
      num := size;
      counts := size::counts;
    end if;

    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("Var " + intString(var) + " would causalize " + intString(size) + " Eqns\n");
    end if;
  end for;
end selectMostCausalizingVars;


protected function selectCausalizingVars
" returns the variables causalizing at least one equation in the next step and the counts in a second list.
  author: ptaeuber"
  input BackendDAE.AdjacencyMatrix inMt;
  input list<Integer> selVars;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input array<Integer> ass1In;
  input array<Boolean> selEqsSetArray;
  output list<Integer> cVars = {};
  output list<Integer> counts = {};
protected
  list<Integer> row;
  Integer size,num = 0;
algorithm
  for var in selVars loop
    row := arrayGet(inMt, var);
    arrayUpdate(ass1In,var,1);
    size := 0;
    for i in row loop
      if arrayGet(selEqsSetArray,i) then
        size := sizeOfAssignable(i,me,ass1In,size);
      end if;
    end for;
    arrayUpdate(ass1In,var,-1);

    if not size == 0 then
      cVars := var::cVars;
      counts := size::counts;
    end if;

    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("Var " + intString(var) + " would causalize " + intString(size) + " Eqns\n");
    end if;
  end for;
end selectCausalizingVars;


protected function selectOneMostCausalizingVar
" determines one variable causalizing the most equations in the next step.
  author: ptaeuber"
  input BackendDAE.AdjacencyMatrix inMt;
  input list<Integer> selVars;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input array<Integer> ass1In;
  input array<Boolean> selEqsSetArray;
  output list<Integer> cVars = {};
  output Integer outMax = 0;
protected
  list<Integer> row;
  Integer size;
algorithm
  for var in selVars loop
    row := arrayGet(inMt, var);
    arrayUpdate(ass1In,var,1);
    size := 0;
    for i in row loop
      if arrayGet(selEqsSetArray,i) then
        size := sizeOfAssignable(i,me,ass1In,size);
      end if;
    end for;
    arrayUpdate(ass1In,var,-1);

    if intGe(size,outMax) then
      cVars := {var};
      outMax := size;
    end if;

    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("Var " + intString(var) + " would causalize " + intString(size) + " Eqns\n");
    end if;
  end for;
end selectOneMostCausalizingVar;


protected function getOneVarWithMostPoints
 "function to find a variable from inVarList with most points in corresponding inPointsLst.
  author: ptaeuber"
  input list<Integer> inVarList;
  input list<Integer> inPointsLst;
  output list<Integer> outVarList={};
  output Integer outMax;
protected
  Integer index=1;
algorithm
  outMax := max(i for i in inPointsLst);
  for i in inPointsLst loop
    if i==outMax then
      outVarList := {listGet(inVarList,index)};
      return;
    end if;
    index := index+1;
  end for;
end getOneVarWithMostPoints;


protected function getAllVarsWithMostPoints
 "function to find all variables from inVarList with most points in corresponding inPointsLst.
  author: ptaeuber"
  input list<Integer> inVarList;
  input list<Integer> inPointsLst;
  input output list<Integer> outVarList={};
  input output Integer outMax=-1;
algorithm
  _ := match(inVarList, inPointsLst)
    local
      Integer p,v;
      list<Integer> prest,vrest;
    case(v::{}, p::{})
      equation
        if intGt(p, outMax) then
          outMax = p;
          outVarList = {v};
        elseif intEq(p, outMax) then
          outVarList = v::outVarList;
        end if;
      then ();
    case(v::vrest, p::prest)
      equation
        if intGt(p, outMax) then
          outMax = p;
          outVarList = {v};
        elseif intEq(p, outMax) then
          outVarList = v::outVarList;
        end if;
        (outVarList, outMax) = getAllVarsWithMostPoints(vrest, prest, outVarList, outMax);
      then ();
    else
      equation
        Error.addCompilerError("Tearing.getAllVarsWithMostPoints: Finding variables with most points failed.");
        fail();
      then ();
  end match;
end getAllVarsWithMostPoints;


protected function sizeOfAssignable
" calculates the number of equations a potential tvar would
  causalize considering the impossible assignments
  author: ptaeuber FHB 2013-10"
  input Integer Eqn;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input array<Integer> ass1;
  input Integer inSize;
  output Integer outSize;
protected
  BackendDAE.AdjacencyMatrixElementEnhanced vars;
  Boolean b;
algorithm
  vars := List.removeOnTrue(ass1,isAssignedSaveEnhanced,me[Eqn]);
  b := solvableLst(vars);
  outSize := if b then inSize+1 else inSize;
end sizeOfAssignable;


protected function getAllVarsWithMostImpAss
" function to return the variables with the highest number of impossible assignments
  considering the current matching
  author: ptaeuber FHB 2013-10"
  input list<Integer> inPotentials;
  input array<Integer> ass2;
  input BackendDAE.AdjacencyMatrixEnhanced meT;
  output list<Integer> outPotentials={};
  output list<Integer> outCounts={};
  output Integer outMax=0;
protected
  Integer count;
  BackendDAE.AdjacencyMatrixElementEnhanced elem;
algorithm
  for v in inPotentials loop
    elem := List.removeOnTrue(ass2,isAssignedSaveEnhanced,meT[v]);
    count := countImpossibleAss(elem);

    if count > outMax then
      outPotentials := {v};
      outMax := count;
    elseif count == outMax then
      outPotentials := v::outPotentials;
    end if;
    outCounts := count::outCounts;

    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("Var " + intString(v) + " has " + intString(count) + " incident impossible assignments\n");
    end if;
  end for;
  outCounts := listReverse(outCounts);
end getAllVarsWithMostImpAss;


protected function getOneVarWithMostImpAss
" function to return one variable with the highest number of impossible assignments
  considering the current matching
  author: ptaeuber"
  input list<Integer> inPotentials;
  input array<Integer> ass2;
  input BackendDAE.AdjacencyMatrixEnhanced meT;
  output list<Integer> outPotentials={};
  output Integer outMax=-1;
protected
  Integer count;
  BackendDAE.AdjacencyMatrixElementEnhanced elem;
algorithm
  for v in inPotentials loop
    elem := List.removeOnTrue(ass2,isAssignedSaveEnhanced,meT[v]);
    count := countImpossibleAss(elem);

    if count > outMax then
      outPotentials := {v};
      outMax := count;
    end if;

    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("Var " + intString(v) + " has " + intString(count) + " incident impossible assignments\n");
    end if;
  end for;
end getOneVarWithMostImpAss;


protected function countImpossibleAss
" helper function for getAllVarsWithMostImpAss,
  traverses AdjacencyMatrixElementEnhanced and counts the number of impossible assignments of one var
  author: ptaeuber FHB 2013-10"
  input BackendDAE.AdjacencyMatrixElementEnhanced elem;
  output Integer outCount = 0;
protected
  BackendDAE.Solvability s;
algorithm
  for e in elem loop
    (_,s,_) := e;
    if not solvable(s) then
      outCount := outCount + 1;
    end if;
  end for;
end countImpossibleAss;


protected function TarjanMatching "Modified matching algorithm according to Tarjan as it is used by Cellier.
  author: ptaeuber 2013-2015"
  input BackendDAE.AdjacencyMatrix mIn;
  input BackendDAE.AdjacencyMatrixT mtIn;
  input BackendDAE.AdjacencyMatrixEnhanced meIn;
  input array<Integer> ass1In,ass2In;
  input list<Integer> orderIn;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input array<Integer> eqnNonlinPoints;
  output list<Integer> orderOut;
  output Boolean causal;
protected
  list<Integer> subOrder,unassigned;
  list<Integer> order=orderIn;
  Boolean assignable = true;
  constant Boolean debug = false;
algorithm
  while assignable loop
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("\nTarjanAssignment:\n");
    end if;
    (order,assignable) := TarjanAssignment(mIn,mtIn,meIn,ass1In,ass2In,order,mapEqnIncRow,mapIncRowEqn,eqnNonlinPoints);
  end while;
  if debug then execStat("Tearing.TarjanMatching iters done"); end if;

  unassigned := getUnassigned(ass1In);
  if listEmpty(unassigned) then
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("\ncausal\n");
    end if;
    orderOut := listReverse(order);
    causal := true;
  else
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("\nnoncausal\n");
    end if;
    orderOut := order;
    causal := false;
  end if;
  if debug then execStat("Tearing.TarjanMatching done"); end if;
end TarjanMatching;


protected function TarjanAssignment " finds assignable equations and variables and assigns
author: ptaeuber FHB 2013-2015"
  input BackendDAE.AdjacencyMatrix mIn;
  input BackendDAE.AdjacencyMatrixT mtIn;
  input BackendDAE.AdjacencyMatrixEnhanced meIn;
  input array<Integer> ass1In,ass2In;
  input list<Integer> orderIn;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input array<Integer> eqnNonlinPoints;
  output list<Integer> orderOut = orderIn;
  output Boolean assignable = false;
protected
  Integer eq_coll;
  list<Integer> assEq_coll, eqns = {}, vars = {};
algorithm
  // find equations with one variable
  assEq_coll := traverseCollectiveEqnsforAssignable(ass2In,mIn,mapEqnIncRow);

  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
     print("New assEq_coll: "+stringDelimitList(List.map(assEq_coll,intString),",")+"\n");
  end if;

  // NOTE: For tearing of strong components with the same number of equations and variables and with a late choice of the
  //       residual equation it is not possible to match starting from the variables, so this case is not considered.
  //       For other tearing structures this case has to be added.

  // Get the next solvable equation from the equation queue
  try
    (eq_coll,eqns,vars) := getNextSolvableEqn(assEq_coll,mIn,meIn,ass1In,ass2In,mapEqnIncRow,mapIncRowEqn,eqnNonlinPoints);
    orderOut := eq_coll::orderOut;
    assignable := true;
  else
  end try;

  // Make the assignment if possible
  if assignable then
    makeAssignment(eqns,vars,ass1In,ass2In,mIn,mtIn);
  end if;

  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("order: "+stringDelimitList(List.map(listReverse(orderOut),intString),",")+"\n\n");
  end if;
end TarjanAssignment;


protected function traverseSingleEqnsforAssignable
" selects next equations that can be causalized without consideration of solvability
  author: ptaeuber FHB 2013-10"
  input array<Integer> inAss;
  input BackendDAE.AdjacencyMatrix m;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  output list<Integer> selectedrows;
protected
  Integer eqnColl,eqnSize;
  DoubleEnded.MutableList<Integer> delst;
algorithm
  delst := DoubleEnded.empty(0);
  for e in 1:arrayLength(inAss) loop
    if arrayGet(inAss,e)<>-1 then
      continue;
    end if;
    eqnColl := mapIncRowEqn[e];
    eqnSize := listLength(mapEqnIncRow[eqnColl]);
    if listLength(m[e]) == eqnSize + 1 then
      if eqnSize == 1 then
        DoubleEnded.push_back(delst, e);
      else
        DoubleEnded.push_front(delst, e);
      end if;
    end if;
  end for;
  selectedrows := DoubleEnded.toListAndClear(delst);
end traverseSingleEqnsforAssignable;


protected function traverseCollectiveEqnsforAssignable
" selects next collective equations that can be causalized without consideration of solvability
  author: ptaeuber"
  input array<Integer> inAss;
  input BackendDAE.AdjacencyMatrix m;
  input array<list<Integer>> mapEqnIncRow;
  output list<Integer> selectedrows;
protected
  Integer eqnSize,e,eqnColl=0;
  DoubleEnded.MutableList<Integer> delst;
algorithm
  delst := DoubleEnded.empty(0);
  for eqnLst in  mapEqnIncRow loop
    eqnColl := eqnColl + 1;
    e := listHead(eqnLst);
    if arrayGet(inAss,e)<>-1 then
      continue;
    end if;
    eqnSize := listLength(eqnLst);
    if listLength(m[e]) == eqnSize then
      if eqnSize == 1 then
        DoubleEnded.push_back(delst, eqnColl);
      else
        DoubleEnded.push_front(delst, eqnColl);
      end if;
    end if;
  end for;
  selectedrows := DoubleEnded.toListAndClear(delst);
end traverseCollectiveEqnsforAssignable;


protected function makeAssignment
" function to assign equations with variables
  author: ptaeuber FHB 2013-10"
  input list<Integer> eqns,vars;
  input array<Integer> ass1In,ass2In;
  input BackendDAE.AdjacencyMatrix mIn;
  input BackendDAE.AdjacencyMatrixT mtIn;
protected
  Integer eq, var;
algorithm
  for index in 1:listLength(eqns) loop
    eq := listGet(eqns, index);
    var := listGet(vars, index);
    arrayUpdate(ass1In,var,eq);
    arrayUpdate(ass2In,eq,var);
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("assignment: Eq " + intString(eq) + " - Var " + intString(var) + "\n");
    end if;
    _ := Array.replaceAtWithFill(eq,{},{},mIn);
    deleteEntriesFromAdjacencyMatrix(mIn,mtIn,{var});
    _ := Array.replaceAtWithFill(var,{},{},mtIn);
    deleteEntriesFromAdjacencyMatrix(mtIn,mIn,{eq});
  end for;
end makeAssignment;


protected function getNextSolvableEqn " finds equation that can be matched with respect to solvability
  author: ptaeuber FHB 2013-08"
  input list<Integer> assEq_coll;
  input BackendDAE.AdjacencyMatrix m;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input array<Integer> eqnNonlinPoints;
  output Integer eqOut;
  output list<Integer> eqnsOut;
  output list<Integer> varsOut;
protected
  Boolean solvable = false;
  list<Integer> eqns = assEq_coll;
algorithm
  while not listEmpty(eqns) loop
    eqOut := getMostNonlinearEquation(eqnNonlinPoints, eqns, mapEqnIncRow, mapIncRowEqn);
    (solvable, eqnsOut, varsOut) := eqnSolvableCheck(eqOut, mapEqnIncRow, ass1, m, me);
    eqns := List.deleteMember(eqns, eqOut);
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("Most nonlinear equation: " + intString(eqOut) + " - solvable?: " + boolString(solvable) + "\n");
    end if;
    if solvable then
      break;
    else
      for eq in mapEqnIncRow[eqOut] loop
        arrayUpdate(ass2,eq,-2);
      end for;
    end if;
  end while;
  if not solvable then fail(); end if;
end getNextSolvableEqn;


protected function eqnSolvableCheck "
  returns the expanded equation(s), variables and
  a boolean whether the equation is solvable or not
  author: ptaeuber FHB 2016"
  input Integer eqn_coll;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> ass1;
  input BackendDAE.AdjacencyMatrix m;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  output Boolean solvable;
  output list<Integer> eqns;
  output list<Integer> vars;
protected
  Integer eqn;
  BackendDAE.AdjacencyMatrixElementEnhanced vars_enh;
algorithm
  eqns := mapEqnIncRow[eqn_coll];
  eqn := listHead(eqns);
  vars := arrayGet(m,eqn);
  vars_enh := List.removeOnTrue(ass1, isAssignedSaveEnhanced,me[eqn]);
  solvable := solvableLst(vars_enh);
end eqnSolvableCheck;


protected function assignInnerEquations " assigns innerEquations for TearingSet
  author: ptaeuber FHB 2013-08"
  input list<Integer> inEqns "order of equations with local numbering";
  input list<Integer> eindex "equation indexes with global numbering";
  input list<Integer> vindex "variable indexes with global numbering";
  input array<Integer> ass2;
  input array<list<Integer>> mapEqnIncRow;
  input Option<BackendDAE.AdjacencyMatrixEnhanced> meOpt;
  output BackendDAE.InnerEquations outInnerEquations;
algorithm
  outInnerEquations := list(
    match (eqn,meOpt)
      local
        Integer eq,otherEqn;
        list<Integer> eqns,vars,otherVars,rest;
        BackendDAE.InnerEquation innerEquation;
        BackendDAE.Constraints constraints;
        BackendDAE.AdjacencyMatrixEnhanced me;
      case (eq,NONE())
        equation
          vars = List.map1r(mapEqnIncRow[eq],arrayGet,ass2);
          otherEqn = listGet(eindex,eq);
          otherVars = selectFromList_rev(vindex,vars);
       then BackendDAE.INNEREQUATION(eqn=otherEqn, vars=otherVars);
      case (eq,SOME(me))
        equation
          eqns = mapEqnIncRow[eq];
          vars = List.map1r(eqns,arrayGet,ass2);
          otherEqn = listGet(eindex,eq);
          otherVars = selectFromList_rev(vindex,vars);
          constraints = findConstraintForInnerEquation(me[listHead(eqns)],listHead(vars));
          if listEmpty(constraints) then
            innerEquation = BackendDAE.INNEREQUATION(eqn=otherEqn, vars=otherVars);
          else
            innerEquation = BackendDAE.INNEREQUATIONCONSTRAINTS(eqn=otherEqn, vars=otherVars, cons=constraints);
          end if;
       then (innerEquation);
    end match for eqn in inEqns);
end assignInnerEquations;


protected function findConstraintForInnerEquation
  input BackendDAE.AdjacencyMatrixElementEnhanced meRow;
  input Integer searchIndex;
  output BackendDAE.Constraints constraints={};
protected
  Integer index;
  BackendDAE.AdjacencyMatrixElementEnhancedEntry meElem;
  BackendDAE.Constraints cons;
algorithm
  for meElem in meRow loop
    (index,_,cons) := meElem;
    if intEq(index,searchIndex) then
      constraints := cons;
      break;
    end if;
  end for;
end findConstraintForInnerEquation;


protected function markTVarsOrResiduals
" marks several tVars in ass1 or residuals in ass2
  author: ptaeuber FHB 2013-10"
  input list<Integer> markList;
  input array<Integer> assIn;
  output array<Integer> assOut = assIn;
protected
  Integer len;
algorithm
  len := arrayLength(assIn);
  for i in markList loop
    arrayUpdate(assOut, i, len * 2);
  end for;
end markTVarsOrResiduals;

protected function countMultiples "counts multiple entries in array<list<Integer row(list)-wise.
counter gives the maximum amount of same entries and value gives the corresponding entry.
if only 0s appear in the row, then (0,0).
author: Waurich TUD 2013-01"
  input array<list<Integer>> inArr;
  output list<Integer> counter,numbers,values;
algorithm
  ((counter,numbers,values,_)) := Array.fold(inArr,countMultiples2,({},{},{},1));
end countMultiples;


protected function countMultiples2 " FoldFunc for countMultiples.if entries appear equaly often,
just one is taken.
author: Waurich TUD 2013-01"
  input list<Integer> rowIn;
  input tuple<list<Integer>,list<Integer>,list<Integer>,Integer> valIn;
  output tuple<list<Integer>,list<Integer>,list<Integer>,Integer> valOut;
protected
  list<Integer> counter,values,row,set,num,val,positions,numbers;
  Integer indx,value,number,position;
algorithm
  (counter,_,values,indx) := valIn;
  row := List.removeOnTrue(0,intEq,rowIn);
  set := List.unique(row);
  if listEmpty(set) then
    val := {0};
    num := {0};
  else
    (val,num) := countMultiples3(row,set,{},{});
  end if;
  positions := maxListInt(num);
  position := listHead(positions);
  number := listGet(num,position);
  numbers := selectFromList(val,positions);
  value := listGet(val,position);
  counter := List.set(counter,indx,number);
  values := List.set(values,indx,value);
  valOut := (counter,numbers,values,indx+1);
end countMultiples2;


protected function countMultiples3 " helper function for countMultiples2.
author:Waurich TUD 2013-01"
  input list<Integer> lstIn;
  input list<Integer> set;
  input list<Integer> valIn;
  input list<Integer> numIn;
  output list<Integer> valOut;
  output list<Integer> numOut;
algorithm
  (valOut,numOut) := match(lstIn,set,valIn,numIn)
    local
      Integer value,number;
      list<Integer> val,num,rest;
    case(_,value::rest,_,_)
      equation
        number = listLength(lstIn)-listLength(List.removeOnTrue(value,intEq,lstIn));
        (val,num) = countMultiples3(lstIn,rest,value::valIn,number::numIn);
      then
        (val,num);
    else (valIn,numIn);
  end match;
end countMultiples3;


protected function maxListInt
  "function to find maximum Integers in inList and output a list with the indexes.
  author: Waurich TUD 2012-11"
  input list<Integer> inList;
  output list<Integer> outList={};
protected
  Integer maxi, index=1;
algorithm
  maxi := max(i for i in inList);
  for i in inList loop
    if i==maxi then
      outList := index::outList;
    end if;
    index := index+1;
  end for;
end maxListInt;


protected function getMostNonlinearEquation
  "Function to find maximum Integers in a selection of inArray and outputs the first index.
  author: ptaeuber"
  input array<Integer> inArray;
  input list<Integer> inList;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  output Integer index=1;
protected
  Integer maxi;
algorithm
  maxi := max(inArray[listHead(mapEqnIncRow[i])] for i in inList);

  for i in inList loop
    index := listHead(mapEqnIncRow[i]);
    if inArray[index] == maxi then
      index := mapIncRowEqn[index];
      return;
    end if;
  end for;
end getMostNonlinearEquation;


protected function selectFromList_rev" selects Ints from inList by indexes given in selList
author: Waurich TUD 2012-11"
  input List<Integer> inList,selList;
  output List<Integer> outList;
protected
  Integer actual;
  Integer len;
  List<Integer> lst = selList;
algorithm
  len := listLength(inList);
  outList := list(listGet(inList,num) for num guard num > 0 and num <= len in selList);
end selectFromList_rev;


protected function selectFromList " selects Ints from inList by indexes given in selList in reverse order.
auhtor: Waurich TUD 2012-11"
  input List<Integer> inList,selList;
  output List<Integer> outList = {};
protected
  Integer num,actual,len;
  List<Integer> lst = selList;
algorithm
  len := listLength(inList);
  for num in selList loop
    if num > 0 and num <= len then
      actual := listGet(inList,num);
      outList := actual::outList;
    end if;
  end for;
end selectFromList;


protected function deleteEntriesFromAdjacencyMatrix "Deletes given entries from matrix. Applicable on Adjacency and on transposed Adjacency.
  author: ptaeuber 2015-02"
  input BackendDAE.AdjacencyMatrix mUpdate;
  input BackendDAE.AdjacencyMatrix mHelp;
  input list<Integer> entries;
protected
  Integer rowIndx;
  list<Integer> rowsIndx, row;
algorithm
  for entry in entries loop
    rowsIndx := arrayGet(mHelp,entry);
    for rowIndx in rowsIndx loop
      row := arrayGet(mUpdate,rowIndx);
      row := List.deleteMember(row,entry);
      Array.replaceAtWithFill(rowIndx,row,row,mUpdate);
    end for;
  end for;
end deleteEntriesFromAdjacencyMatrix;


protected function deleteRowsFromAdjacencyMatrix "Deletes given rows from matrix. Applicable on Adjacency and on transposed Adjacency.
  author: ptaeuber 2015-02"
  input BackendDAE.AdjacencyMatrix mUpdate;
  input list<Integer> rows;
algorithm
  for row in rows loop
    _ := Array.replaceAtWithFill(row,{},{},mUpdate);
  end for;
end deleteRowsFromAdjacencyMatrix;


protected function getVarsOfEqnsWithMostVars "find vars occurring in the equations with the
  most variables considering the current matching.
  author: ptaeuber"
  input list<Integer> inVars;
  input BackendDAE.AdjacencyMatrix mIn;
  input BackendDAE.AdjacencyMatrixT mtIn;
  output list<Integer> outVars = {};
protected
  Integer size, maxSize = 0;
  list<Integer> eqns;
  array<Integer> eqn_size_arr;
algorithm
  eqn_size_arr := arrayCreate(arrayLength(mIn),-1);
  for i in 1:arrayLength(mIn) loop
    size := listLength(mIn[i]);
    eqn_size_arr[i] := size;
    if size > maxSize then
      maxSize := size;
    end if;
  end for;

  for var in inVars loop
    eqns := mtIn[var];
    for e in eqns loop
      if eqn_size_arr[e] == maxSize then
        outVars := var :: outVars;
        break;
      end if;
    end for;
  end for;
  GC.free(eqn_size_arr);
end getVarsOfEqnsWithMostVars;


protected function getVarsOccurringInMostEquations
 "find rows in transposed adjacency matrix enhanced with most nonzero
  elements and put the indexes of these rows in a list.
  author: ptaeuber"
  input BackendDAE.AdjacencyMatrixT mtIn;
  input list<Integer> inSelect;
  output Integer length = 0;
  output list<Integer> outLst = {};
protected
  Integer length1;
  list<Integer> row;
algorithm
  for sel in inSelect loop
    row := arrayGet(mtIn, sel);
    length1 := listLength(row);
    if intGt(length1,length) then
      length := length1;
      outLst := {sel};
    elseif intEq(length1,length) then
      outLst := sel::outLst;
    end if;
  end for;
end getVarsOccurringInMostEquations;


protected function getVarOccurringInMostEquations "find rows in transposed adjacency matrix enhanced with most nonzero
  elements. Return the first found row index with most entries.
author: ptaeuber"
  input BackendDAE.AdjacencyMatrixT mtIn;
  input list<Integer> inSelect;
  output Integer length = 0;
  output list<Integer> outLst = {};
protected
  Integer length1;
  list<Integer> row;
algorithm
  for sel in inSelect loop
    row := arrayGet(mtIn, sel);
    length1 := listLength(row);
    if intGt(length1,length) then
      length := length1;
      outLst := {sel};
    end if;
  end for;
end getVarOccurringInMostEquations;


protected function findNEntries " find rows with n nonzero elements and
put the indexes of these rows in a list.
author: Waurich TUD 2012-10"
  input BackendDAE.AdjacencyMatrix mtIn;
  input list<Integer> inSelect;
  input Integer num;
  output list<Integer> outList = {};
protected
  Integer length;
  list<Integer> row;
algorithm
  for sel in inSelect loop
    row := arrayGet(mtIn, sel);
    length := listLength(row);
    if intEq(num,length) then
      outList := sel::outList;
    end if;
  end for;
end findNEntries;

// =============================================================================
// section for preOptModule >>recursiveTearing<<
//
// inline and repeat tearing
// author: Vitalij Ruge
// =============================================================================

public function recursiveTearing
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  Boolean con;
algorithm
  if Flags.getConfigInt(Flags.RTEARING) > 0 then
    (outDAE, con) := recursiveTearingMain(inDAE);
    while con loop
      outDAE := tearingSystem(outDAE);
      (outDAE, con) := recursiveTearingMain(outDAE);
    end while;
  else
    outDAE := inDAE;
  end if;
end recursiveTearing;

protected function recursiveTearingMain
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
  output Boolean update = false;
protected
  list<BackendDAE.EqSystem> systlst_new = {};
  BackendDAE.Shared shared;
  DAE.FunctionTree funcs;
  BackendDAE.Variables vars, globalKnownVars;
  BackendDAE.StrongComponents comps;
  BackendDAE.EquationArray eqns;
  BackendDAE.StateSets stateSets;
  BackendDAE.BaseClockPartitionKind partitionKind;

  BackendDAE.InnerEquations innerEquations;
  BackendDAE.InnerEquation innerEquation;
  Integer eqindex, vindex;
  list<Integer> residualequations;
  list<Integer> tearingvars, othervars;
  list<BackendDAE.Var> var_lst;
  BackendDAE.Var var;
  array<DAE.ComponentRef> tear_cr;
  list<DAE.ComponentRef> tear_cr_lst, all_vars = {};
  array<DAE.Exp> tear_exp;
  DAE.ComponentRef cr, cr1;
  BackendDAE.Equation eqn, eqn1;
  DAE.Exp rhs, lhs, rhs1, lhs1, rhs_, lhs_, sumRhs, sumLhs, lhs_f, e, res;
  Integer n, i, j, m, k, index = 1;
  array<Option<BackendDAE.Equation>> optarr, optarr_res;
  array<Integer> indx_res, indx_eq, indx_var;
  Boolean tmp_update, isDer;
  BackendDAE.AdjacencyMatrix mm;
  Boolean maxSizeOne =  Flags.getConfigInt(Flags.RTEARING) == 1;
  list<DAE.Exp> loopT, noLoopT;
algorithm
  shared := inDAE.shared;
  BackendDAE.SHARED(functionTree=funcs, globalKnownVars=globalKnownVars) := shared;
  //BackendDump.bltdump("IN:", inDAE);
  for syst in inDAE.eqs loop
    BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,matching=BackendDAE.MATCHING(comps=comps),stateSets=stateSets,partitionKind=partitionKind) := syst;
    (_, mm, _) := BackendDAEUtil.getAdjacencyMatrix(syst, BackendDAE.SPARSE(), SOME(funcs), BackendDAEUtil.isInitializationDAE(shared));
    tmp_update := false;
    for comp in comps loop
      if isTornsystem(comp, true, false) then
        // -----
        BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(innerEquations = innerEquations, residualequations= residualequations, tearingvars=tearingvars)) := comp;
        n := listLength(innerEquations);
        m := listLength(residualequations);
        if maxSizeOne and m > 1 then
          continue;
        end if;
        indx_res := arrayCreate(m,0);
        indx_var := arrayCreate(n,0);
        indx_eq := arrayCreate(n,0);
        i := 1;
        optarr := arrayCreate(n, NONE());
        update := true;
        tmp_update := true;
        // -----
        for innerEquation in innerEquations loop
          (eqindex, {vindex}, _) := BackendDAEUtil.getEqnAndVarsFromInnerEquation(innerEquation);
          (var as BackendDAE.VAR(varName = cr)) := BackendVariable.getVarAt(vars, vindex);
          all_vars := cr :: all_vars;
          arrayUpdate(indx_var,i,vindex);
          eqn := BackendEquation.get(eqns, eqindex);
          if BackendVariable.isStateVar(var) then
            eqn := BackendEquation.solveEquation(eqn, Expression.expDer(Expression.crefExp(cr)), SOME(funcs));
          else
            eqn := BackendEquation.solveEquation(eqn, Expression.crefExp(cr), SOME(funcs));
          end if;
          arrayUpdate(optarr, i, SOME(eqn));
          eqns := BackendEquation.setAtIndex(eqns, eqindex, eqn);
          arrayUpdate(indx_eq, i , eqindex);
          i := i + 1;
          if Flags.isSet(Flags.DUMP_RTEARING) then
            print("INeqn => " + BackendDump.equationString(eqn) +  "[" + intString(i-1) + "]\n");
          end if;
        end for; //innerEquations

        // -----
        var_lst := list(BackendVariable.getVarAt(vars, i) for i in tearingvars);
        tear_cr_lst := list(BackendVariable.varCref(vv) for vv in var_lst);
        tear_cr  := listArray(tear_cr_lst);
        all_vars := listAppend(tear_cr_lst, all_vars);
        tear_exp  := arrayCreate(m, DAE.RCONST(0.0));
        i := 1;
        for tcr in tear_cr  loop
          arrayUpdate(tear_exp, i, Expression.crefExp(tcr));
          i := i +1;
        end for; //cr
        // -----
        optarr_res := arrayCreate(m, NONE());

        for i in 1:m loop
          eqindex :: residualequations := residualequations;
          arrayUpdate(indx_res, i , eqindex);
          eqn := BackendEquation.get(eqns, eqindex);
          if Flags.isSet(Flags.DUMP_RTEARING) then
            print("INres => " + BackendDump.equationString(eqn) + "[" + intString(i) + "]\n");
          end if;
          arrayUpdate(optarr_res, i, SOME(eqn));
        end for;

        for i in 1:n  loop
          SOME(eqn) := arrayGet(optarr, i);
          rhs := BackendEquation.getEquationRHS(eqn);
          lhs := BackendEquation.getEquationLHS(eqn);
          (cr,isDer) := Expression.expOrDerCref(lhs);

          //print("*****" + ExpressionDump.printExpStr(lhs) + "= " +  ExpressionDump.printExpStr(rhs) + "*******\n");
          for j in (i+1):n loop
            if listMember(arrayGet(indx_var,i) , arrayGet(mm, arrayGet(indx_eq,j))) then
              SOME(eqn1) := arrayGet(optarr, j);
              //print("\n (" + intString(i) + "," + intString(j) + ") => \n" + BackendDump.equationString(eqn1));
              rhs1 := BackendEquation.getEquationRHS(eqn1);
              rhs1 := recursiveTearingReplace(rhs1, cr, rhs, isDer);
              rhs1 := recursiveTearingCollect(tear_exp, rhs1);
              (index, vars, eqns, shared, _, e, _, _, _) := BackendDAEOptimize.simplifyLoopExp(index, vars, eqns, shared, all_vars, rhs1, {}, {}, true, true,-1,{}, "RTEARING");
              eqn1 := BackendEquation.setEquationRHS(eqn1, e);
              //print( "=>" + BackendDump.equationString(eqn1) + "\n");
              arrayUpdate(optarr,j,SOME(eqn1));
            end if;
          end for; // j

          //res eqn
          for j in 1:m loop
            if listMember(arrayGet(indx_var,i) , arrayGet(mm, arrayGet(indx_res,j))) then
              SOME(eqn1) := arrayGet(optarr_res, j);

              res := BackendDAEOptimize.makeEquationToResidualExp(eqn1);
              res := recursiveTearingCollect(tear_exp, res);
              (loopT, noLoopT) := BackendDAEOptimize.simplifyLoops_SplitTerms(all_vars, res);

              sumRhs := Expression.makeSum1(noLoopT,true);
              sumLhs := Expression.makeSum1(loopT,true);

              sumRhs := recursiveTearingReplace(sumRhs, cr, rhs, isDer);
              sumLhs := recursiveTearingReplace(sumLhs, cr, rhs, isDer);

              sumRhs := recursiveTearingCollect(tear_exp,sumRhs);
              sumLhs := recursiveTearingCollect(tear_exp,sumLhs);

              // RHS
              (sumRhs,_) := ExpressionSimplify.simplify(sumRhs);
              (index, vars, eqns, shared, _, sumRhs, _, _, _) := BackendDAEOptimize.simplifyLoopExp(index, vars, eqns, shared, all_vars, sumRhs, {}, {}, true, true,-1,{}, "RTEARING");
              eqn1 := BackendEquation.setEquationRHS(eqn1, Expression.negate(sumRhs));

              //LHS
              (sumLhs,_) := ExpressionSimplify.simplify(sumLhs);
              (index, vars, eqns, shared, _, sumLhs, _, _, _) := BackendDAEOptimize.simplifyLoopExp(index, vars, eqns, shared, all_vars, sumLhs, {}, {}, true, true,-1,{}, "RTEARING");
              eqn1 := BackendEquation.setEquationLHS(eqn1, sumLhs);
              arrayUpdate(optarr_res,j,SOME(eqn1));
            end if; // listMember
          end for;//j
        end for; // i

        for i in 1:n loop
          eqindex := arrayGet(indx_eq,i);
          SOME(eqn) := arrayGet(optarr, i);
          eqns := BackendEquation.setAtIndex(eqns, eqindex, eqn);
          if Flags.isSet(Flags.DUMP_RTEARING) then
            print("OUTeqn => " + BackendDump.equationString(eqn) + "[" + intString(i-1) + "]\n");
          end if;
        end for; // i

        for i in 1:m loop
          eqindex := arrayGet(indx_res,i);
          SOME(eqn) := arrayGet(optarr_res, i);
          eqns := BackendEquation.setAtIndex(eqns, eqindex, eqn);
          if Flags.isSet(Flags.DUMP_RTEARING) then
            print("OUTres => " + BackendDump.equationString(eqn) +  "[" + intString(i-1) + "]\n");
          end if;
        end for; // i

        if Flags.isSet(Flags.DUMP_RTEARING) then
          print("****************\n");
          for i in 1:m loop
            print("TearVar: " + ExpressionDump.printExpStr(arrayGet(tear_exp, i)) +  "[" + intString(i-1) + "]\n");
          end for;
          print("****************\n");
        end if;

      end if; // isTornsystem
    end for; // comp

    if tmp_update then
      systlst_new := BackendDAEUtil.createEqSystem(vars, eqns, stateSets, partitionKind) :: systlst_new;
    else
      systlst_new := syst :: systlst_new;
    end if;

  end for; // syst
  if update then
    outDAE := BackendDAE.DAE(systlst_new, shared);
    try
      outDAE := BackendDAEUtil.transformBackendDAE(outDAE,SOME((BackendDAE.NO_INDEX_REDUCTION(),BackendDAE.EXACT())),NONE(),NONE());
    else
      update := false;
    end try;
  else
    outDAE := inDAE;
  end if;
  //BackendDAE.DAE(systlst_new) := outDAE;
  //outDAE := BackendDAE.DAE(systlst_new, shared);
  //BackendDump.bltdump("OUT:", outDAE);
end recursiveTearingMain;

protected function recursiveTearingCollect
  input array<DAE.Exp> tear_exp;
  input DAE.Exp inExp;
  output DAE.Exp outExp;
protected
  Integer k;
  DAE.Exp lhs, e1, e2;
algorithm

  (e1, e2) := ExpressionSolve.collectX(inExp, arrayGet(tear_exp, 1));

  for k in 2:arrayLength(tear_exp) loop
    (lhs, e2) := ExpressionSolve.collectX(e2, arrayGet(tear_exp, k));
    e1 := Expression.expAdd(e1, lhs);
  end for;
  outExp := Expression.expAdd(e2, e1);
end recursiveTearingCollect;

protected function isTornsystem
  input BackendDAE.StrongComponent comp;
  input Boolean getLin = true;
  input Boolean getNoLin = false;
  output Boolean res;

algorithm
  res := match comp
         local Boolean linear;

         case  BackendDAE.TORNSYSTEM(linear=linear)
         guard linear == getLin or getNoLin == (not linear)
         then true;
         else false;
         end match;
end isTornsystem;

protected function recursiveTearingHelper
"
 collect expression
"
  input DAE.Exp rhs1;
  input array<DAE.Exp> tear_exp;
  input Integer m;
  output DAE.Exp sumRhs = Expression.makeConstZeroE(rhs1);
protected
  Integer k;
  DAE.Exp e, rhs = rhs1;
algorithm
  for k in 1:m loop
    (e, rhs) := ExpressionSolve.collectX(rhs, arrayGet(tear_exp, k));
    sumRhs := Expression.expAdd(e, sumRhs);
  end for;
  sumRhs := Expression.expAdd(rhs, sumRhs);
  (sumRhs,_) := ExpressionSimplify.simplify(sumRhs);
end recursiveTearingHelper;

protected function recursiveTearingReplace
  input DAE.Exp inExp;
  input DAE.ComponentRef inSourceExp;
  input DAE.Exp inTargetExp;
  input Boolean isDer;
  output DAE.Exp res;
algorithm
  if isDer then
    res := Expression.crefExp(inSourceExp);
    res := Expression.expDer(res);
    (res,_) := Expression.replaceExp(inExp, res, inTargetExp);
  else
    res := Expression.replaceCrefBottomUp(inExp, inSourceExp, inTargetExp);
  end if;

end recursiveTearingReplace;


protected function getUnassigned
  input array<Integer> ass;
  output list<Integer> unassigned={};
algorithm
  for i in 1:arrayLength(ass) loop
    if Dangerous.arrayGetNoBoundsChecking(ass, i) < 0 then
      unassigned := i::unassigned;
    end if;
  end for;
end getUnassigned;


protected function dumpTearingSetLocalIndexes
  input list<Integer> tVars,residuals,order;
  input array<Integer> ass2;
  input Integer size;
  input array<list<Integer>> mapEqnIncRow;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input String setString;
protected
  list<String> s;
algorithm
  print("\n" + BORDER + "\n* TEARING RESULTS" + setString + ":\n* (Local Indexes)\n*\n* No of equations in strong component: "+intString(size)+"\n");
  print("* No of tVars: "+intString(listLength(tVars))+"\n");
  print("*\n* tVars: "+ stringDelimitList(List.map(listReverse(tVars),intString),",") + "\n");
  if Flags.isSet(Flags.ITERATION_VARS) then
    s := list("* " + intString(tVar) + ": " + BackendDump.varString(BackendVariable.getVarAt(vars,tVar)) for tVar in tVars);
    print(stringDelimitList(s, "\n") + "\n");
  end if;
  print("*\n* resEq: "+ stringDelimitList(List.map(residuals,intString),",") + "\n");
  if Flags.isSet(Flags.ITERATION_VARS) and Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    s := list("* " + intString(eqn) + ": " + BackendDump.equationString(BackendEquation.get(eqns,eqn)) for eqn in residuals);
    print(stringDelimitList(s, "\n") + "\n");
  end if;
  s := list("{" + intString(e) + ":" + stringDelimitList(List.map(List.map1r(mapEqnIncRow[e],arrayGet,ass2),intString),",") + "}" for e in order);
  print("*\n* innerEquations ({eqn,vars}):\n* " + stringDelimitList(s,", ") + "\n*\n" + BORDER + "\n\n");
end dumpTearingSetLocalIndexes;


protected function dumpTearingSetGlobalIndexes
  input BackendDAE.TearingSet tearingSet;
  input Integer size;
  input String setString;
protected
  list<Integer> tVars,residuals;
  BackendDAE.InnerEquations innerEquations;
algorithm
  BackendDAE.TEARINGSET(tearingvars=tVars,residualequations=residuals,innerEquations=innerEquations) := tearingSet;
  print("\n" + BORDER + "\n* TEARING RESULTS" + setString + ":\n* (Global Indexes)\n*\n* No of equations in strong component: "+intString(size)+"\n");
  print("* No of tVars: "+intString(listLength(tVars))+"\n");
  print("*\n* tVars: "+ stringDelimitList(List.map(listReverse(tVars),intString),",") + "\n");
  print("*\n* resEq: "+ stringDelimitList(List.map(residuals,intString),",") + "\n");
  print("*\n* innerEquations ({eqn,vars}):\n* " + stringDelimitList(List.map(innerEquations, BackendDump.innerEquationString),", ") + "\n*\n*" + BORDER + "\n\n");
end dumpTearingSetGlobalIndexes;


protected function dumpTearingSetsGlobalIndexes
  input list<BackendDAE.TearingSet> tearingSets;
  input Integer size;
protected
  list<Integer> tVars,residuals;
  BackendDAE.InnerEquations innerEquations;
algorithm
  for tearingSet in tearingSets loop
    dumpTearingSetGlobalIndexes(tearingSet,size,"");
  end for;
end dumpTearingSetsGlobalIndexes;


// =============================================================================
//
// Total Tearing - Determination of All Possible Tearing Sets
// author: ptaeuber FHB 2016
//
// =============================================================================

protected function totalTearing " determination of all possible tearing sets
author: ptaeuber FHB 2016"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> eindex;
  input list<Integer> vindx;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> ojac;
  input BackendDAE.JacobianType jacType;
  input Boolean mixedSystem;
  output BackendDAE.StrongComponent ocomp;
  output Boolean outRunMatching;
protected
  Integer size;
  array<Integer> ass1,ass2,mapIncRowEqn;
  array<list<Integer>> mapEqnIncRow;
  list<Integer> tVars,order,causEq,unsolvables,discreteVars;
  BackendDAE.EqSystem subsyst;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.AdjacencyMatrix m,mLoop;
  BackendDAE.AdjacencyMatrix mt,mtLoop;
  BackendDAE.AdjacencyMatrixEnhanced me;
  BackendDAE.AdjacencyMatrixTEnhanced meT;
  BackendDAE.BackendDAEType DAEtype;
  list<BackendDAE.TearingSet> tearingSets;
  list<BackendDAE.Equation> eqn_lst;
  list<BackendDAE.Var> var_lst;
  Boolean linear,simulation;
  String modelName;
  list<list<Integer>> powerSet={};
  list<tuple<array<Integer>,array<Integer>,list<Integer>>> matchingList;
algorithm
  linear := BackendDAEUtil.getLinearfromJacType(jacType);
  BackendDAE.SHARED(backendDAEType=DAEtype, info=BackendDAE.EXTRA_INFO(fileNamePrefix=modelName)) := ishared;

  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n" + BORDER + "\nBEGINNING of totalTearing\n\n");
  end if;

  // Generate Subsystem to get the adjacency matrix
  size := listLength(vindx);
  eqn_lst := BackendEquation.getList(eindex,BackendEquation.getEqnsFromEqSystem(isyst));
  eqns := BackendEquation.listEquation(eqn_lst);
  var_lst := List.map1r(vindx, BackendVariable.getVarAt, BackendVariable.daeVars(isyst));
  vars := BackendVariable.listVar1(var_lst);
  subsyst := BackendDAEUtil.createEqSystem(vars, eqns);
  (subsyst,m,mt,_,_) := BackendDAEUtil.getAdjacencyMatrixScalar(subsyst, BackendDAE.NORMAL(),NONE(), BackendDAEUtil.isInitializationDAE(ishared));


  // Delete negative entries from adjacency matrix
  m := Array.map(m,deleteNegativeEntries);
  mt := Array.map(mt,deleteNegativeEntries);

  if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n\n###BEGIN print Strong Component#####################\n(Function:totalTearing)\n");
    BackendDump.printEqSystem(subsyst);
    print("\n###END print Strong Component#######################\n(Function:totalTearing)\n\n\n");
  end if;

  // Get advanced adjacency matrix (determine how the variables occur in the equations)
  (me,meT,mapEqnIncRow,mapIncRowEqn) := BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(subsyst,ishared,false);

  // Determine unsolvable vars to consider solvability
  unsolvables := getUnsolvableVars(size,meT);

  if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nAdjacencyMatrixEnhanced:\n");
    BackendDump.dumpAdjacencyMatrixEnhanced(me);
    print("\nAdjacencyMatrixTransposedEnhanced:\n");
    BackendDump.dumpAdjacencyMatrixTEnhanced(meT);
  end if;

  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n\nmapEqnIncRow:"); //+ stringDelimitList(List.map(List.flatten(arrayList(mapEqnIncRow)),intString),",") + "\n\n");
    BackendDump.dumpAdjacencyMatrix(mapEqnIncRow);
    print("\nmapIncRowEqn:\n" + stringDelimitList(List.map(arrayList(mapIncRowEqn),intString),",") + "\n\n");
    print("\n\nUNSOLVABLES:\n" + stringDelimitList(List.map(unsolvables,intString),",") + "\n\n");
  end if;

  // Determine discrete vars
  discreteVars := findDiscrete(var_lst);
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nDiscrete Vars:\n" + stringDelimitList(List.map(discreteVars,intString),",") + "\n\n");
  end if;


  // Determine all possible sets of tearing variables and save them in powerSet
  // ******************************************

  for i in (Util.intPow(2,size)-1):-1:1 loop
    powerSet := getPowerSetElement(i)::powerSet;
  end for;
  if Flags.isSet(Flags.TOTAL_TEARING_DUMP) or Flags.isSet(Flags.TOTAL_TEARING_DUMPVERBOSE) then
    BackendDump.dumpListList(powerSet,"Power Set");
  end if;



  // BEGIN TO LOOP
  // ******************************************
  tearingSets := {};

  if Flags.isSet(Flags.TOTAL_TEARING_DUMP) or Flags.isSet(Flags.TOTAL_TEARING_DUMPVERBOSE) then
    print("\n\n###BEGIN TO LOOP#####################\n" + BORDER + "\n\n\n");
  end if;

  for tVars in powerSet loop
      if Flags.isSet(Flags.TOTAL_TEARING_DUMPVERBOSE) then
        print("\ntVars:\n" + stringDelimitList(List.map(tVars,intString),",") + "\n\n");
      end if;


      // Initialize matching
      ass1 := arrayCreate(size,-1);
      ass2 := arrayCreate(size,-1);
      order := {};

      mLoop := arrayCopy(m);
      mtLoop := arrayCopy(mt);

      // mark tVars in ass1
      markTVarsOrResiduals(tVars, ass1);

      // remove tearing vars from adjacency matrix and transposed adjacency matrix
      deleteEntriesFromAdjacencyMatrix(mLoop, mtLoop, tVars);
      deleteRowsFromAdjacencyMatrix(mtLoop, tVars);

      // initially find equations which can be causalized in the next step and save in causEq
      causEq := traverseCollectiveEqnsforAssignable(ass2,mLoop,mapEqnIncRow);

      // if Flags.isSet(Flags.TOTAL_TEARING_DUMPVERBOSE) then
        // print("\nInitial ass1: " + stringDelimitList(List.map(arrayList(ass1),intString),",")+"\n");
        // print("Initial ass2: " + stringDelimitList(List.map(arrayList(ass2),intString),",") + "\n");
        // print("\nInitial m:");BackendDump.dumpAdjacencyMatrix(mLoop);
        // print("\nInitial mt:");BackendDump.dumpAdjacencyMatrix(mtLoop);
        // print("\nInitial causEq: " + stringDelimitList(List.map(causEq,intString),",") + "\n");
        // print("Initial order: " + stringDelimitList(List.map(order,intString),",") + "\n\n\n\n");
      // end if;


      // Find all possible matchings for this set of tearing variables
      matchingList := totalMatching(ass1,ass2,order,causEq,mLoop,mtLoop,me,mapEqnIncRow,mapIncRowEqn,{});
      if Flags.isSet(Flags.TOTAL_TEARING_DUMPVERBOSE) then
        dumpMatchingList(matchingList);
      end if;

      // save tearing sets in list
      tearingSets := createTearingSets(tVars,matchingList,vindx,eindex,mapEqnIncRow,mapIncRowEqn,tearingSets);

  end for;

  // dump all different tearing sets
  if Flags.isSet(Flags.TOTAL_TEARING_DUMP) or Flags.isSet(Flags.TOTAL_TEARING_DUMPVERBOSE) then
    dumpTearingSetsGlobalIndexes(tearingSets,size);
  end if;

  // Determine the rest of the information needed for BackendDAE.TORNSYSTEM
  // ***************************************************************************
  ocomp := BackendDAE.TORNSYSTEM(listHead(tearingSets),NONE(),linear,mixedSystem);
  outRunMatching := true;

  if Flags.isSet(Flags.TOTAL_TEARING_DUMP) or Flags.isSet(Flags.TOTAL_TEARING_DUMPVERBOSE) then
    print("\n\nTotal number of different tearing sets: " + intString(listLength(tearingSets)) + "\n\n");
  end if;

  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nEND of totalTearing\n" + BORDER + "\n\n");
  end if;
end totalTearing;


protected function getPowerSetElement
  input Integer i;
  output list<Integer> powerSetElement={};
protected
  Integer c=0,e=i,r;
algorithm
  while not intEq(e,0) loop
    c := c+1;
    r := intMod(e,2);
    e := intDiv(e,2);
    if intEq(r,1) then
      powerSetElement := c :: powerSetElement;
    end if;
  end while;
end getPowerSetElement;


protected function totalMatching "function to find all possible matchings for one given set of tearing variables (DFS)
author: ptaeuber FHB 2016"
  input array<Integer> ass1,ass2;
  input list<Integer> orderIn;
  input list<Integer> causEqIn;
  input BackendDAE.AdjacencyMatrix m;
  input BackendDAE.AdjacencyMatrixT mt;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input list<tuple<array<Integer>,array<Integer>,list<Integer>>> matchingListIn;
  output list<tuple<array<Integer>,array<Integer>,list<Integer>>> matchingListOut=matchingListIn;
protected
  list<Integer> order, causEq, e_exp, vars, unassigned;
  array<Integer> ass1Copy,ass2Copy;
  BackendDAE.AdjacencyMatrix mCopy;
  BackendDAE.AdjacencyMatrixT mtCopy;
  Boolean solvable;
algorithm
  for e in causEqIn loop
    // 1. Deep copies to avoid side effects
    ass1Copy := arrayCopy(ass1);
    ass2Copy := arrayCopy(ass2);
    mCopy := arrayCopy(m);
    mtCopy := arrayCopy(mt);

    (solvable, e_exp, vars) := eqnSolvableCheck(e, mapEqnIncRow, ass1Copy, mCopy, me);
    if not solvable then
      continue;
    else
      // 2. Match e_exp with corresponding variable(s), i.e.: update ass1, ass2, m, order
      makeAssignment(e_exp,vars,ass1Copy,ass2Copy,mCopy,mtCopy);
      order := e::orderIn;

      // 3. Determine new possible causEq
      causEq := traverseCollectiveEqnsforAssignable(ass2Copy,mCopy,mapEqnIncRow);

      // 4. Dump
      // if Flags.isSet(Flags.TOTAL_TEARING_DUMPVERBOSE) then
        // print("\nNew ass1: " + stringDelimitList(List.map(arrayList(ass1Copy),intString),",")+"\n");
          // print("New ass2: " + stringDelimitList(List.map(arrayList(ass2Copy),intString),",") + "\n");
        // print("\nNew m:");BackendDump.dumpAdjacencyMatrix(mCopy);
        // print("\nNew mt:");BackendDump.dumpAdjacencyMatrix(mtCopy);
        // print("\nNew causEq: " + stringDelimitList(List.map(causEq,intString),",") + "\n");
          // print("New order: " + stringDelimitList(List.map(order,intString),",") + "\n\n\n\n");
      // end if;

      // 5. Decide what to do
      if listEmpty(causEq) then
        // full matching found?
        unassigned := getUnassigned(ass1Copy);
        if listEmpty(unassigned) then
          // save current full matching
          if isNewMatching(matchingListOut,ass1Copy) then
            matchingListOut := (ass1Copy,ass2Copy,listReverse(order)) :: matchingListOut;
          end if;
        end if;
      else
        // Continue with matching
        matchingListOut := totalMatching(ass1Copy,ass2Copy,order,causEq,mCopy,mtCopy,me,mapEqnIncRow,mapIncRowEqn,matchingListOut);
      end if;
    end if;
  end for;
end totalMatching;


protected function isNewMatching
  input list<tuple<array<Integer>,array<Integer>,list<Integer>>> matchingList;
  input array<Integer> ass1In;
  output Boolean b=true;
protected
  array<Integer> ass1;
algorithm
  for matching in matchingList loop
    (ass1,_,_) := matching;
    if Array.isEqual(ass1In,ass1) then
      b:=false;
      break;
    end if;
  end for;
end isNewMatching;


protected function createTearingSets
  input list<Integer> tVarsIn;
  input list<tuple<array<Integer>,array<Integer>,list<Integer>>> matchingList;
  input list<Integer> vindx;
  input list<Integer> eindex;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  input list<BackendDAE.TearingSet> tearingSetsIn;
  output list<BackendDAE.TearingSet> tearingSetsOut=tearingSetsIn;
protected
  array<Integer> ass1,ass2;
  list<Integer> tVars,residual,residual_coll,order;
  BackendDAE.InnerEquations innerEquations;
algorithm
  for matching in matchingList loop
    (ass1,ass2,order) := matching;

    // Unassigned equations are residual equations
    residual := getUnassigned(ass2);
    residual_coll := List.map1r(residual,arrayGet,mapIncRowEqn);
    residual_coll := List.unique(residual_coll);

    // Convert indexes
    tVars := selectFromList_rev(vindx, tVarsIn);
    residual := selectFromList_rev(eindex, residual_coll);

    // assign innerEquations:
    innerEquations := assignInnerEquations(order,eindex,vindx,ass2,mapEqnIncRow,NONE());

    // Create BackendDAE.TearingSet for strict set
    tearingSetsOut := BackendDAE.TEARINGSET(tVars,residual,innerEquations,BackendDAE.EMPTY_JACOBIAN()) :: tearingSetsOut;

    if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("\nTearing Variables:\n" + stringDelimitList(List.map(tVarsIn,intString),",") +"\n");
      print("Residual Equations:\n" + stringDelimitList(List.map(residual_coll,intString),",") +"\n\n");
    end if;
  end for;
end createTearingSets;


protected function dumpMatchingList
  input list<tuple<array<Integer>,array<Integer>,list<Integer>>> matchingList;
protected
  Integer c=0;
  list<Integer> order;
  array<Integer> ass1, ass2;
algorithm
  print("\n");
  for matching in matchingList loop
    c := c+1;
    (ass1,ass2,order) := matching;
    print("Matching " + intString(c) + ":\n");
    print("ass1: " + stringDelimitList(List.map(arrayList(ass1),intString),",") + "\n");
    print("ass2: " + stringDelimitList(List.map(arrayList(ass2),intString),",") + "\n");
    print("order: " + stringDelimitList(List.map(order,intString),",") + "\n\n");
  end for;
end dumpMatchingList;

// =============================================================================
//
// User-Defined Tearing - Determine the tearing set defined by the user
// author: ptaeuber FHB 2016
//
// =============================================================================

protected function userDefinedTearing " determine the tearing set defined by the user
author: ptaeuber FHB 2016"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> eindex;
  input list<Integer> vindx;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> ojac;
  input BackendDAE.JacobianType jacType;
  input Boolean mixedSystem;
  input list<Integer> userTVars;
  input list<Integer> userResiduals;
  output BackendDAE.StrongComponent ocomp;
  output Boolean outRunMatching;
protected
  Integer size;
  array<Integer> ass1,ass2,mapIncRowEqn;
  array<list<Integer>> mapEqnIncRow;
  list<Integer> tVars,residuals,order,causEq,unsolvables,discreteVars,userResiduals_exp;
  BackendDAE.EqSystem subsyst;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.AdjacencyMatrix m;
  BackendDAE.AdjacencyMatrix mt;
  BackendDAE.AdjacencyMatrixEnhanced me;
  BackendDAE.AdjacencyMatrixTEnhanced meT;
  BackendDAE.BackendDAEType DAEtype;
  BackendDAE.InnerEquations innerEquations;
  BackendDAE.TearingSet tearingSet;
  list<BackendDAE.Equation> eqn_lst;
  list<BackendDAE.Var> var_lst;
  Boolean linear;
  String modelName;
algorithm

  linear := BackendDAEUtil.getLinearfromJacType(jacType);
  BackendDAE.SHARED(backendDAEType=DAEtype, info=BackendDAE.EXTRA_INFO(fileNamePrefix=modelName)) := ishared;

  // Generate Subsystem to get the adjacency matrix
  size := listLength(vindx);
  eqn_lst := BackendEquation.getList(eindex,BackendEquation.getEqnsFromEqSystem(isyst));
  eqns := BackendEquation.listEquation(eqn_lst);
  var_lst := List.map1r(vindx, BackendVariable.getVarAt, BackendVariable.daeVars(isyst));
  vars := BackendVariable.listVar1(var_lst);
  subsyst := BackendDAEUtil.createEqSystem(vars, eqns);
  (subsyst,m,mt,_,_) := BackendDAEUtil.getAdjacencyMatrixScalar(subsyst, BackendDAE.NORMAL(),NONE(), BackendDAEUtil.isInitializationDAE(ishared));

  // Delete negative entries from adjacency matrix
  m := Array.map(m,deleteNegativeEntries);
  mt := Array.map(mt,deleteNegativeEntries);

  // Get advanced adjacency matrix (determine how the variables occur in the equations)
  (me,meT,mapEqnIncRow,mapIncRowEqn) := BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(subsyst,ishared,false);

  // Expand algorithm or equation array residual equations
  try
    userResiduals_exp := List.flatten(list(arrayGet(mapEqnIncRow, i) for i in userResiduals));
  else
    Error.addMessage(Error.USER_DEFINED_TEARING_ERROR, {"Index out of bounds."});
    fail();
  end try;


  // Dumps
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n" + BORDER + "\nBEGINNING of userDefinedTearing\n\n");
  end if;

  if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nUsers tearing vars: " + stringDelimitList(List.map(userTVars,intString),",") + "\n");
    print("\nUsers residual equations: " + stringDelimitList(List.map(userResiduals,intString),",") + "\n");
    print("\nUsers residual equations expanded: " + stringDelimitList(List.map(userResiduals_exp,intString),",") + "\n");
    print("\n\n###BEGIN print Strong Component#####################\n(Function:userDefinedTearing)\n");
    BackendDump.printEqSystem(subsyst);
    print("\n###END print Strong Component#######################\n(Function:userDefinedTearing)\n\n\n");
  end if;

  if not intEq(listLength(userTVars),listLength(userResiduals_exp)) then
    Error.addMessage(Error.USER_DEFINED_TEARING_ERROR, {"The number of tearing variables and residual equations is not identical."});
    fail();
  end if;

  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nAdjacencyMatrixEnhanced:\n");
    BackendDump.dumpAdjacencyMatrixEnhanced(me);
    print("\nAdjacencyMatrixTransposedEnhanced:\n");
    BackendDump.dumpAdjacencyMatrixTEnhanced(meT);
  end if;

  // Determine unsolvable vars to consider solvability
  unsolvables := getUnsolvableVars(size,meT);

  // Determine discrete vars
  discreteVars := findDiscrete(var_lst);

  // Dumps
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\n\nmapEqnIncRow:"); //+ stringDelimitList(List.map(List.flatten(arrayList(mapEqnIncRow)),intString),",") + "\n\n");
    BackendDump.dumpAdjacencyMatrix(mapEqnIncRow);
    print("\nmapIncRowEqn:\n" + stringDelimitList(List.map(arrayList(mapIncRowEqn),intString),",") + "\n\n");
    print("\n\nUNSOLVABLES:\n" + stringDelimitList(List.map(unsolvables,intString),",") + "\n\n");
    print("\nDiscrete Vars:\n" + stringDelimitList(List.map(discreteVars,intString),",") + "\n\n");
  end if;

  // Initialize matching
  ass1 := arrayCreate(size,-1);
  ass2 := arrayCreate(size,-1);
  order := {};

  // mark userTVars in ass1
  markTVarsOrResiduals(userTVars, ass1);
  // mark userResiduals in ass2
  markTVarsOrResiduals(userResiduals_exp, ass2);

  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nass1: " + stringDelimitList(List.map(arrayList(ass1),intString),",") + "\n");
    print("ass2: " + stringDelimitList(List.map(arrayList(ass2),intString),",") + "\n");
  end if;

  // remove tearing vars from adjacency matrix and transposed adjacency matrix
  deleteEntriesFromAdjacencyMatrix(m, mt, userTVars);
  deleteRowsFromAdjacencyMatrix(mt, userTVars);
  // remove residual equations from adjacency matrix and transposed adjacency matrix
  deleteEntriesFromAdjacencyMatrix(mt, m, userResiduals_exp);
  deleteRowsFromAdjacencyMatrix(m, userResiduals_exp);

  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nAdjacency Matrix without tvars and residuals:\n");
    BackendDump.dumpAdjacencyMatrix(m);
    BackendDump.dumpAdjacencyMatrix(mt);
  end if;

  if intEq(listLength(userTVars), countEmptyRows(m)) and intEq(listLength(userResiduals_exp), countEmptyRows(mt)) then
    // Find initial causalizable equations
    causEq := traverseCollectiveEqnsforAssignable(ass2,m,mapEqnIncRow);

    // Call the matching algorithm
    order := simpleMatching(ass1,ass2,order,causEq,m,mt,me,mapEqnIncRow,mapIncRowEqn);

    // Convert indexes
    tVars := selectFromList_rev(vindx, userTVars);
    residuals := selectFromList_rev(eindex, userResiduals);

    // assign innerEquation:
    innerEquations := assignInnerEquations(order,eindex,vindx,ass2,mapEqnIncRow,NONE());

    tearingSet := BackendDAE.TEARINGSET(tVars,residuals,innerEquations,BackendDAE.EMPTY_JACOBIAN());

    // Create BackendDAE.TornSystem
    ocomp := BackendDAE.TORNSYSTEM(tearingSet,NONE(),linear,mixedSystem);
    outRunMatching := true;

    // dump results with local indexes
    if Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      dumpTearingSetLocalIndexes(userTVars,userResiduals,order,ass2,size,mapEqnIncRow,vars,eqns,"");
    end if;

    // dump results with global indexes
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      dumpTearingSetGlobalIndexes(tearingSet,size,"");
    end if;

  else
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("\nMatching failed, choose different tearing set!\n\n\n");
    end if;
    Error.addCompilerError("There is no possible matching for a user-defined tearing set.");
    fail();

  end if;

  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nEND of userDefinedTearing\n" + BORDER + "\n\n");
  end if;
end userDefinedTearing;


protected function countEmptyRows
"function to count empty rows in adjacency matrices"
  input BackendDAE.AdjacencyMatrix m;
  output Integer count=0;
algorithm
  for row in m loop
    if listEmpty(row) then
      count := count + 1;
    end if;
  end for;
end countEmptyRows;


protected function simpleMatching "function tries to find a matching based on a given set of tearing variables and residual equations
author: ptaeuber FHB 2016"
  input array<Integer> ass1,ass2;
  input list<Integer> orderIn;
  input list<Integer> causEqIn;
  input BackendDAE.AdjacencyMatrix m;
  input BackendDAE.AdjacencyMatrixT mt;
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  output list<Integer> orderOut=orderIn;
protected
  Integer e;
  list<Integer> causEq=causEqIn, e_exp, vars;
algorithm
  if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
    print("\nStart Matching:\n"+ UNDERLINE + "\n");
  end if;
  while not listEmpty(causEq) loop
    try
      (e,e_exp,vars) := getNextSolvableEqn(causEq,m,me,ass1,ass2,mapEqnIncRow,mapIncRowEqn,ass1);
    else
      if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
        print("\nMatching failed, choose different tearing set!\n\n\n");
      end if;
      Error.addCompilerError("There is no possible matching for a user-defined tearing set.");
      fail();
    end try;

    // Dump
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("causEq: " + stringDelimitList(List.map(causEq,intString),",") + "\nProcess " + intString(e) + ":\ne_exp: " + stringDelimitList(List.map(e_exp,intString),",") + "\n");
    end if;

    // Match e_exp with corresponding variable(s), i.e.: update ass1, ass2, m, order
    makeAssignment(e_exp,vars,ass1,ass2,m,mt);
    orderOut := e::orderOut;

    // Determine new possible causEq
    causEq := traverseCollectiveEqnsforAssignable(ass2,m,mapEqnIncRow);
  end while;
  if listEmpty(getUnassigned(ass1)) then
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("\nMatching succeeded!\n");
    end if;
    orderOut := listReverse(orderOut);
  else
    if Flags.isSet(Flags.TEARING_DUMPVERBOSE) then
      print("\nMatching failed, choose different tearing set!\n\n\n");
    end if;
    Error.addCompilerError("There is no possible matching for a user-defined tearing set.");
    fail();
  end if;
end simpleMatching;

// ============================================================================
// Section for guru tearing
//   Use only tearingSelect.always variables as tearing variables and force
//   all other variables to be inner variables. Can invoke inner loops.
// ============================================================================
protected function guruTearing
  "Forces tearing and inner variables defined by the all knowing guru."
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> eindex;
  input list<Integer> vindx;
  input BackendDAE.JacobianType jacType;
  input Boolean mixedSystem;
  output BackendDAE.StrongComponent ocomp;
protected
  list<BackendDAE.Equation> eqn_lst, residual_eqn_lst = {};
  list<BackendDAE.Var> var_lst, tearing_var_lst, inner_var_lst;
  array<Integer> ass1, ass2, ass1_manipulated, scalToArr;
  BackendDAE.EquationArray eqns;
  BackendDAE.Variables vars;
  BackendDAE.AdjacencyMatrix m;
  list<list<Integer>> sorted_inner_comps;
  BackendDAE.InnerEquations innerEquations = {};
  list<Integer> tearing_var_indices, residual_eqn_indices = {};
  Boolean linear;
algorithm
  // ALGORITHM ABSTRACT
  //   1. get all equations and variables of the algebraic loop
  //   2. split variables in tearing and inner variables using TearingSelect.Always
  //   3. use existing matching information to extract residual equations
  //   4. manipulate existing matching information to represent the system without tearing variables and residual equations
  //   5. sort the manipulated system to get inner strong components

  // 1. get all equations and variables
  eqn_lst := BackendEquation.getList(eindex, BackendEquation.getEqnsFromEqSystem(isyst));
  var_lst := List.map1r(vindx, BackendVariable.getVarAt, isyst.orderedVars);

  // 2. split variables in tearing and inner variables
  (tearing_var_lst, inner_var_lst) := List.splitOnTrue(var_lst, BackendVariable.varTearingSelectAlways);
  tearing_var_indices := list(i for i guard(BackendVariable.varTearingSelectAlways(BackendVariable.getVarAt(isyst.orderedVars, i))) in vindx);

  BackendDAE.MATCHING(ass1 = ass1, ass2 = ass2) := isyst.matching;
  SOME((_, scalToArr, _, _, _)) := isyst.mapping;
  ass1_manipulated := arrayCopy(ass1);
  for i in tearing_var_indices loop
    // 3. use existing matching information to extract residual equations
    residual_eqn_indices := ass1[i] :: residual_eqn_indices;
    // 4. manipulate existing matching information to represent the system without tearing variables and residual equations
    ass1_manipulated[i] := -1;
  end for;

  SOME(m) := isyst.m;
  sorted_inner_comps := Sorting.Tarjan(m, ass1_manipulated);
  linear := BackendDAEUtil.getLinearfromJacType(jacType);
  innerEquations := list(innerStrongComponent(comp, ass2, scalToArr, linear, mixedSystem) for comp in sorted_inner_comps);

  ocomp := BackendDAE.TORNSYSTEM(
    strictTearingSet  = BackendDAE.TEARINGSET(
      tearingvars         = listReverse(tearing_var_indices),
      residualequations   = listReverse(residual_eqn_indices),
      innerEquations      = innerEquations,
      jac                 = BackendDAE.EMPTY_JACOBIAN()),
    casualTearingSet  = NONE(),
    linear            = linear,
    mixedSystem       = mixedSystem);
end guruTearing;

protected function innerStrongComponent
  input list<Integer> comp;
  input array<Integer> ass2;
  input array<Integer> scalToArr;
  input Boolean linear;
  input Boolean mixed;
  output BackendDAE.InnerEquation innerEqn;
protected
  list<Integer> eqn_indices = List.unique(list(scalToArr[i] for i in comp));
  list<Integer> var_indices = list(ass2[i] for i in comp);
algorithm
  if listLength(eqn_indices) == 1 then
    innerEqn := BackendDAE.INNEREQUATION(List.first(eqn_indices), var_indices);
  else
    //kab: ToDo actually compute jacobian, linear and mixed
    innerEqn := BackendDAE.INNERLOOP(
      set = BackendDAE.TEARINGSET(
        tearingvars       = var_indices,
        residualequations = eqn_indices,
        innerEquations    = {},
        jac               = BackendDAE.EMPTY_JACOBIAN()),
      linear = linear or false,
      mixed = mixed and true);
  end if;
end innerStrongComponent;

annotation(__OpenModelica_Interface="backend");
end Tearing;
