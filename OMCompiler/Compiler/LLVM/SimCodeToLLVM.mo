/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package SimCodeToLLVM
" file:        SimCodeToLLVM.mo
  package:     SimCodeToLLVM
  description: Lowers a SimCode.SIMCODE down to in-memory LLVM IR via
               EXT_LLVM and runs the simulation through the existing
               C-side solver+result-file plumbing -- no cc invocation,
               no .so on disk. Parallel to MidToLLVM (which handles
               MetaModelica function bodies for +d=jit_eval_func on
               function-call evaluation); this module is the
               simulate(model) entry point for the same flag.

  Initial scope (Phase 1, the iteration that lands this file):
  - explicit-ODE models with der(x) = f(x, params, time)
  - scalar Real states and algebraic vars
  - fixed Euler step
  - csv result file
  - no events, no nonlinear systems, no when-equations, no arrays.

  Out of scope for now (later iterations): events / zero-crossings,
  linear/nonlinear systems, mixed systems, algorithms, arrays,
  DASSL/IDA, FMI export.

  author: John Tinnerholm
"
public
import EXT_LLVM;
import SimCode;

protected
import Absyn;
import AbsynUtil;
import DAE;
import Error;
import List;
import SimCodeVar;
import SimCodeFunction;

public function genSim
  "Lower a SimCode.SIMCODE to in-memory LLVM IR + run the simulation
   driver against it. Returns true on success; on any unsupported
   construct the caller (Ceval simulate hook) must fail() so the
   matchcontinue falls back to the legacy buildModel C path.

   This is a skeleton -- Phase 1 lands the entry point + the
   model-info traversal so we can stage subsequent phases on top.
   Until the per-equation lowering and driver are wired up (Phase 4-6),
   the function flags every model as unsupported and returns false."
  input SimCode.SimCode simCode;
  output Boolean success;
protected
  Absyn.Path name;
  SimCodeVar.SimVars vars;
  list<SimCode.SimEqSystem> odeEqs;
  Integer nStates, nAlgs, nParams;
algorithm
  name := simCodeName(simCode);
  vars := simCodeVars(simCode);
  odeEqs := flattenOdeEquations(simCode);
  nStates := listLength(simVars_stateVars(vars));
  nAlgs := listLength(simVars_algVars(vars));
  nParams := listLength(simVars_paramVars(vars));
  /* TODO Phase 4: per-equation lowering via simEqSystemToLLVM.
   * TODO Phase 5: emit omc_ode_<name>(double t, double[] x,
   *   double[] xd, double[] params) entry point.
   * TODO Phase 6: link the small C-side simulation driver against
   *   the JIT module, return populated SimulationResult.
   * Until then: refuse and let the caller fall back. */
  Error.addInternalError(
    "SimCodeToLLVM: model '" + AbsynUtil.pathString(name) +
    "' (states=" + intString(nStates) +
    " algs=" + intString(nAlgs) +
    " params=" + intString(nParams) +
    " odeEqs=" + intString(listLength(odeEqs)) +
    ") -- per-equation lowering and driver not yet implemented; falling back to legacy buildModel\n",
    sourceInfo());
  success := false;
end genSim;

protected function simCodeName
  input SimCode.SimCode simCode;
  output Absyn.Path name;
algorithm
  name := match simCode
    case SimCode.SIMCODE(modelInfo=SimCode.MODELINFO(name=name)) then name;
  end match;
end simCodeName;

protected function simCodeVars
  input SimCode.SimCode simCode;
  output SimCodeVar.SimVars vars;
algorithm
  vars := match simCode
    case SimCode.SIMCODE(modelInfo=SimCode.MODELINFO(vars=vars)) then vars;
  end match;
end simCodeVars;

protected function flattenOdeEquations
  "Collapse the list<list<SimEqSystem>> ode partitions into a single
   list. The outer list is over partitions -- for the explicit-ODE
   scope we accept there is exactly one partition, but flattening
   keeps the traversal robust against multi-partition models we will
   need to reject explicitly in later phases."
  input SimCode.SimCode simCode;
  output list<SimCode.SimEqSystem> eqs;
algorithm
  eqs := match simCode
    local list<list<SimCode.SimEqSystem>> parts;
    case SimCode.SIMCODE(odeEquations=parts)
      then List.flatten(parts);
  end match;
end flattenOdeEquations;

protected function simVars_stateVars
  input SimCodeVar.SimVars vars;
  output list<SimCodeVar.SimVar> stateVars;
algorithm
  stateVars := match vars
    case SimCodeVar.SIMVARS(stateVars=stateVars) then stateVars;
  end match;
end simVars_stateVars;

protected function simVars_algVars
  input SimCodeVar.SimVars vars;
  output list<SimCodeVar.SimVar> algVars;
algorithm
  algVars := match vars
    case SimCodeVar.SIMVARS(algVars=algVars) then algVars;
  end match;
end simVars_algVars;

protected function simVars_paramVars
  input SimCodeVar.SimVars vars;
  output list<SimCodeVar.SimVar> paramVars;
algorithm
  paramVars := match vars
    case SimCodeVar.SIMVARS(paramVars=paramVars) then paramVars;
  end match;
end simVars_paramVars;

annotation(__OpenModelica_Interface="backend");
end SimCodeToLLVM;
