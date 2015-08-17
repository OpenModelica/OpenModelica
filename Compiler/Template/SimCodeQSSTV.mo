interface package SimCodeQSSTV

package BackendQSS
  uniontype QSSinfo "- equation indices in static blocks and DEVS structure"
    record QSSINFO
      list<list<Integer>> stateVarIndex;
      list<DAE.ComponentRef> stateVars;
      list<DAE.ComponentRef> discreteAlgVars;
      list<DAE.ComponentRef> algVars;
      BackendDAE.EqSystems eqs;
      list<DAE.Exp> zcs;
      Integer zc_offset;
    end QSSINFO;
  end QSSinfo;

  function getStateIndexList
    input QSSinfo qssInfo;
    output list<list<Integer>> refs;
  end getStateIndexList;

  function getStates
    input QSSinfo qssInfo;
    output list<DAE.ComponentRef> refs;
  end getStates;

  function getDisc
    input QSSinfo qssInfo;
    output list<DAE.ComponentRef> refs;
  end getDisc;
  function replaceVars
    input DAE.Exp exp;
    input list<DAE.ComponentRef> states;
    input list<DAE.ComponentRef> disc;
    input list<DAE.ComponentRef> algs;
    output DAE.Exp expout;
  end replaceVars;

  function replaceCref
    input DAE.ComponentRef cr;
    input list<DAE.ComponentRef> states;
    input list<DAE.ComponentRef> disc;
    input list<DAE.ComponentRef> algs;
    output String out;
  end replaceCref;

  function getAlgs
    input QSSinfo qssInfo;
    output list<DAE.ComponentRef> refs;
  end getAlgs;

  function negate
    input DAE.Exp exp;
    output DAE.Exp exp_out;
  end negate;

  function getEqs
    input QSSinfo qssInfo;
    output BackendDAE.EquationArray eqs;
  end getEqs;

  function generateHandler
    input BackendDAE.EquationArray eqs;
    input list<Integer> handlers;
    input list<DAE.ComponentRef> states;
    input list<DAE.ComponentRef> disc;
    input list<DAE.ComponentRef> algs;
    input DAE.Exp condition;
    input Boolean v;
    input list<DAE.Exp> zc_exps;
    input Integer offset;
    output String out;
    end generateHandler;


  function getRHSVars
    input list<DAE.Exp> beqs;
    input list<SimCodeVar.SimVar> vars;
    input list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
    input list<DAE.ComponentRef> states;
    input list<DAE.ComponentRef> disc;
    input list<DAE.ComponentRef> algs;
    output list<DAE.ComponentRef> out;
  end getRHSVars;

  function getDiscRHSVars
    input list<DAE.Exp> beqs;
    input list<SimCodeVar.SimVar> vars;
    input list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
    input list<DAE.ComponentRef> states;
    input list<DAE.ComponentRef> disc;
    input list<DAE.ComponentRef> algs;
    output list<DAE.ComponentRef> out;
  end getDiscRHSVars;


  function generateDInit
    input  list<DAE.ComponentRef> disc;
    //input  list<SimCode.SampleCondition> sample;
    input  SimCodeVar.SimVars vars;
    input  Integer acc;
    input  Integer total;
    input  Integer nWhenClause;
    output String out;
  end generateDInit;

  function generateExtraParams
    input SimCode.SimEqSystem eq;
    input SimCodeVar.SimVars vars;
    output String s;
  end generateExtraParams;

  function generateInitialParamEquations
    input  SimCode.SimEqSystem eq;
    output String t;
  end generateInitialParamEquations;

  function replaceVarsInputs
    input DAE.Exp exp;
    input list<DAE.ComponentRef> inp;
    output DAE.Exp exp_out;
  end replaceVarsInputs;

  function getZCOffset
    input QSSinfo qssInfo;
    output Integer o;
  end getZCOffset;

  function getZCExps
    input QSSinfo qssInfo;
    output list<DAE.Exp> exps;
  end getZCExps;

end BackendQSS;

end SimCodeQSSTV;
