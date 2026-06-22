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

  Phase 4.1: classify equations + map every cref to (kind, index)
             using SimCodeVar.SIMVARS.

  Initial scope:
  - explicit-ODE models with der(x) = f(x, params, time)
  - scalar Real states and algebraic vars
  - fixed Euler step
  - csv result file
  - no events, no nonlinear systems, no when-equations, no arrays.

  Runtime contract: the JIT-compiled module must plug into the
  existing OMC C runtime (SimulationRuntime/c) -- the same DATA*,
  threadData_t*, real_array, and solver-callback shapes the
  templated C code uses today. In Phase 5+ the entry point we emit
  will have the canonical signature
      int <prefix>_functionODE(DATA *data, threadData_t *threadData)
  and read/write through data->localData[0]->realVars[i] rather
  than via standalone double* buffers. The (kind, index) layout
  computed here is the bridge: kind selects which realVars slice
  to use (states are 0..nStates-1, derivatives are nStates..2*nStates-1,
  alg vars come next, etc.; see omc_init.c).

  Style: pure match throughout (no matchcontinue), no fail()-based
  control flow. Helpers return Boolean ok / Option<...>; callers
  propagate. Exhaustive cases over uniontypes; unsupported variants
  short-circuit with Boolean false.

  author: John Tinnerholm
"
public
import EXT_LLVM;
import SimCode;

protected
import Absyn;
import AbsynUtil;
import ComponentReferenceBasics;
import DAE;
import Error;
import List;
import SimCodeVar;
import SimCodeFunction;

/* ====================================================================== *
 *  Variable layout                                                       *
 * ====================================================================== */

public uniontype VarKind
  "Where in the omc_ode(double t, double *x, double *xd, double *params)
   contract a SimVar lives. Iteration-1 scope only carries state,
   derivative, alg (treated as x for now since algs come from the
   ODE residual evaluator in trivial models), and param. Anything
   else makes a model UNSUPPORTED for SimCodeToLLVM and the legacy
   buildModel path takes over."
  record VK_STATE      end VK_STATE;
  record VK_DERIVATIVE end VK_DERIVATIVE;
  record VK_ALG        end VK_ALG;
  record VK_PARAM      end VK_PARAM;
end VarKind;

public uniontype VarSlot
  record VAR_SLOT
    VarKind kind;
    Integer index "0-based offset within the kind's array";
    DAE.Type ty;
  end VAR_SLOT;
end VarSlot;

public uniontype VarLayout
  "Flat lookup table: ComponentRef -> VarSlot. Built once per
   genSim call from SimCodeVar.SIMVARS by enumerating each bucket."
  record VAR_LAYOUT
    list<tuple<DAE.ComponentRef, VarSlot>> entries;
    Integer nStates;
    Integer nAlgs;
    Integer nParams;
  end VAR_LAYOUT;
end VarLayout;

/* ====================================================================== *
 *  Equation classification                                               *
 * ====================================================================== */

public uniontype EqRecipe
  "How a SimEqSystem will be lowered. Phase 4.1 only produces the
   recipe; Phase 4.4 consumes it to emit IR."
  record EQ_STATE_ASSIGN
    "x[idx] := exp (initial-equation or start-value form)."
    Integer slotIndex;
    DAE.Exp rhs;
  end EQ_STATE_ASSIGN;

  record EQ_DERIVATIVE_ASSIGN
    "xd[idx] := exp (an ODE simple-assigned equation)."
    Integer slotIndex;
    DAE.Exp rhs;
  end EQ_DERIVATIVE_ASSIGN;

  record EQ_ALG_ASSIGN
    "alg[idx] := exp (a non-state algebraic var assigned)."
    Integer slotIndex;
    DAE.Exp rhs;
  end EQ_ALG_ASSIGN;

  record EQ_UNSUPPORTED
    "Reason the equation cannot be lowered in the current scope."
    String reason;
  end EQ_UNSUPPORTED;
end EqRecipe;

/* ====================================================================== *
 *  Entry point                                                           *
 * ====================================================================== */

public function genSim
  "Lower a SimCode.SIMCODE to in-memory LLVM IR + run the simulation
   driver against it. Returns true on success; false on any
   unsupported construct (so the caller in SimCodeMain.generateModelCode
   falls back to the legacy template-based C path).

   Phase 4.1: build the variable layout, classify all ODE
   equations, log the result. No IR is emitted yet. Returns
   false so the legacy path stays in charge."
  input SimCode.SimCode simCode;
  output Boolean success;
protected
  Absyn.Path name;
  SimCodeVar.SimVars vars;
  list<SimCode.SimEqSystem> odeEqs;
  VarLayout layout;
  list<EqRecipe> recipes;
  Integer nSupported, nUnsupported;
algorithm
  name := simCodeName(simCode);
  vars := simCodeVars(simCode);
  odeEqs := flattenOdeEquations(simCode);

  layout := buildVarLayout(vars);
  recipes := List.map1(odeEqs, classifySimEq, layout);

  nSupported   := List.fold(recipes, countSupported, 0);
  nUnsupported := List.fold(recipes, countUnsupported, 0);

  Error.addInternalError(
    "SimCodeToLLVM: model '" + AbsynUtil.pathString(name) +
    "' layout: nStates=" + intString(layout.nStates) +
    " nAlgs=" + intString(layout.nAlgs) +
    " nParams=" + intString(layout.nParams) +
    "; eqs: supported=" + intString(nSupported) +
    " unsupported=" + intString(nUnsupported) +
    " (Phase 4.1 -- per-equation IR emission not yet wired; falling " +
    "back to legacy buildModel)\n",
    sourceInfo());
  success := false;
end genSim;

/* ====================================================================== *
 *  SimCode field extractors (single-record uniontypes, so match)         *
 * ====================================================================== */

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
   scope there is one partition, but flattening keeps the traversal
   robust against multi-partition models the upper layer will reject."
  input SimCode.SimCode simCode;
  output list<SimCode.SimEqSystem> eqs;
algorithm
  eqs := match simCode
    local list<list<SimCode.SimEqSystem>> parts;
    case SimCode.SIMCODE(odeEquations=parts)
      then List.flatten(parts);
  end match;
end flattenOdeEquations;

/* ====================================================================== *
 *  VarLayout build                                                       *
 * ====================================================================== */

protected function buildVarLayout
  "Walk the four SIMVARS buckets we currently care about and
   accumulate the cref -> slot entries. SimVar.index is already
   1-based-per-kind in master; we keep that as-is and the IR
   layer will subtract 1 when generating GEP offsets."
  input SimCodeVar.SimVars vars;
  output VarLayout layout;
protected
  list<SimCodeVar.SimVar> stateVars, derivativeVars, algVars, paramVars;
  list<tuple<DAE.ComponentRef, VarSlot>> entries = {};
algorithm
  (stateVars, derivativeVars, algVars, paramVars) := match vars
    case SimCodeVar.SIMVARS(stateVars=stateVars,
                            derivativeVars=derivativeVars,
                            algVars=algVars,
                            paramVars=paramVars)
      then (stateVars, derivativeVars, algVars, paramVars);
  end match;

  for v in stateVars      loop entries := addEntry(v, VK_STATE(),      entries); end for;
  for v in derivativeVars loop entries := addEntry(v, VK_DERIVATIVE(), entries); end for;
  for v in algVars        loop entries := addEntry(v, VK_ALG(),        entries); end for;
  for v in paramVars      loop entries := addEntry(v, VK_PARAM(),      entries); end for;

  layout := VAR_LAYOUT(entries,
                      listLength(stateVars),
                      listLength(algVars),
                      listLength(paramVars));
end buildVarLayout;

protected function addEntry
  input SimCodeVar.SimVar v;
  input VarKind kind;
  input list<tuple<DAE.ComponentRef, VarSlot>> entries;
  output list<tuple<DAE.ComponentRef, VarSlot>> outEntries;
algorithm
  outEntries := match v
    local DAE.ComponentRef cr;
          Integer i;
          DAE.Type ty;
    case SimCodeVar.SIMVAR(name=cr, index=i, type_=ty)
      then (cr, VAR_SLOT(kind, i, ty)) :: entries;
  end match;
end addEntry;

public function lookupSlot
  "Linear scan; the table is small for the explicit-ODE scope.
   Returns NONE() rather than failing so the caller propagates a
   Boolean ok instead of jumping out via exception."
  input DAE.ComponentRef cref;
  input VarLayout layout;
  output Option<VarSlot> slot;
algorithm
  slot := lookupSlotEntries(cref, layout.entries);
end lookupSlot;

protected function lookupSlotEntries
  input DAE.ComponentRef cref;
  input list<tuple<DAE.ComponentRef, VarSlot>> entries;
  output Option<VarSlot> slot = NONE();
protected
  DAE.ComponentRef cr;
  VarSlot s;
algorithm
  for entry in entries loop
    (cr, s) := entry;
    if ComponentReferenceBasics.crefEqual(cref, cr) then
      slot := SOME(s);
      return;
    end if;
  end for;
end lookupSlotEntries;

/* ====================================================================== *
 *  Equation classification                                               *
 * ====================================================================== */

protected function classifySimEq
  "Map a SimEqSystem to an EqRecipe. The only directly-lowerable
   shape for Phase 4 is SES_SIMPLE_ASSIGN with a CREF lhs that
   resolves to a state derivative, a state, or an algebraic var.
   Anything else is marked UNSUPPORTED with a short reason string
   so the diagnostic in genSim is informative when falling back."
  input SimCode.SimEqSystem eq;
  input VarLayout layout;
  output EqRecipe recipe;
algorithm
  recipe := match eq
    local DAE.ComponentRef cref;
          DAE.Exp rhs;
          Option<VarSlot> os;
          VarSlot s;
    case SimCode.SES_SIMPLE_ASSIGN(cref=cref, exp=rhs)
      algorithm
        os := lookupSlot(cref, layout);
      then match os
        case SOME(s as VAR_SLOT(kind=VK_DERIVATIVE()))
          then EQ_DERIVATIVE_ASSIGN(s.index, rhs);
        case SOME(s as VAR_SLOT(kind=VK_STATE()))
          then EQ_STATE_ASSIGN(s.index, rhs);
        case SOME(s as VAR_SLOT(kind=VK_ALG()))
          then EQ_ALG_ASSIGN(s.index, rhs);
        case SOME(VAR_SLOT(kind=VK_PARAM()))
          then EQ_UNSUPPORTED("simple-assign to parameter not allowed");
        else
          then EQ_UNSUPPORTED("cref not found in layout: "
                              + ComponentReferenceBasics.printComponentRefStr(cref));
      end match;
    case SimCode.SES_RESIDUAL()
      then EQ_UNSUPPORTED("SES_RESIDUAL requires solver, deferred");
    case SimCode.SES_LINEAR()
      then EQ_UNSUPPORTED("SES_LINEAR requires solver, deferred");
    case SimCode.SES_NONLINEAR()
      then EQ_UNSUPPORTED("SES_NONLINEAR requires solver, deferred");
    case SimCode.SES_MIXED()
      then EQ_UNSUPPORTED("SES_MIXED requires solver, deferred");
    case SimCode.SES_WHEN()
      then EQ_UNSUPPORTED("SES_WHEN requires event handling, deferred");
    case SimCode.SES_IFEQUATION()
      then EQ_UNSUPPORTED("SES_IFEQUATION requires event handling, deferred");
    case SimCode.SES_ALGORITHM()
      then EQ_UNSUPPORTED("SES_ALGORITHM requires statement lowering, deferred");
    case SimCode.SES_ARRAY_CALL_ASSIGN()
      then EQ_UNSUPPORTED("SES_ARRAY_CALL_ASSIGN requires array lowering, deferred");
    case SimCode.SES_FOR_LOOP()
      then EQ_UNSUPPORTED("SES_FOR_LOOP requires loop lowering, deferred");
    case SimCode.SES_FOR_EQUATION()
      then EQ_UNSUPPORTED("SES_FOR_EQUATION requires loop lowering, deferred");
    else
      then EQ_UNSUPPORTED("unhandled SimEqSystem variant");
  end match;
end classifySimEq;

protected function countSupported
  input EqRecipe r;
  input Integer acc;
  output Integer out;
algorithm
  out := match r
    case EQ_UNSUPPORTED() then acc;
    else acc + 1;
  end match;
end countSupported;

protected function countUnsupported
  input EqRecipe r;
  input Integer acc;
  output Integer out;
algorithm
  out := match r
    case EQ_UNSUPPORTED() then acc + 1;
    else acc;
  end match;
end countUnsupported;

annotation(__OpenModelica_Interface="backend");
end SimCodeToLLVM;
