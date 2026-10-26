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

encapsulated package NBDataReconciliation
" file:         NBDataReconciliation.mo
  package:      NBDataReconciliation
  description:  Extraction algorithm for data reconciliation, computes the
                auxiliary conditions (SET-C) and intermediate equations (SET-S).
"

protected
  import Module = NBModule;

  import BackendDAE = NBackendDAE;
  import BackendExtension = NFBackendExtension;
  import Causalize = NBCausalize;
  import ComponentRef = NFComponentRef;
  import NBEquation.{Equation, EqData};
  import StrongComponent = NBStrongComponent;
  import NFBackendExtension.Uncertainty;
  import BVariable = NBVariable;
  import NBVariable.{VariablePointers, VarData};
  import Variable = NFVariable;

  // Util
  import Flags;
  import List;
  import SCodeUtil;
  import StringUtil;

public constant String UNDERLINE = "==========================================================================";

public function main extends Module.wrapper;
  input String fileNamePrefix;
protected
  list<Pointer<Variable>> knowns, boundaryConditions;
  list<StrongComponent> comps, bindingComps;
algorithm
  print("\nModelInfo: " + fileNamePrefix + "\n" + UNDERLINE + "\n\n");

  () := match bdae
    local
      VarData varData;
      EqData eqData;
    case BackendDAE.MAIN(varData = varData as VarData.VAR_DATA_SIM(), eqData = eqData as EqData.EQ_DATA_SIM()) algorithm
      (_, comps) := Causalize.simple(varData.unknowns, eqData.simulation, NBPartition.Kind.ODE);
      bindingComps := list(c for c guard(isBindingComponent(c)) in comps);
      dumpComponents(comps, "Standard BLT of the original model");

      (knowns, boundaryConditions, _, _) := getVariableCategories(VariablePointers.toList(varData.unknowns));
      dumpVarList(knowns, "Variables of interest");
      dumpVarList(boundaryConditions, "Boundary conditions");
      dumpComponents(bindingComps, "Binding equations");
    then ();
  end match;
end main;

public function isEnabled
  output Boolean b = List.isMemberOnTrue("dataReconciliation", Flags.getConfigStringList(Flags.PRE_OPT_MODULES), stringEq)
                  or List.isMemberOnTrue("dataReconciliation", Flags.getConfigStringList(Flags.PRE_OPT_MODULES_ADD), stringEq);
end isEnabled;

protected function getVariableCategories
  "knowns: uncertain = Uncertainty.refine
   boundaryConditions: annotation(__OpenModelica_BoundaryCondition = true)
   exactEquationVars: all others
   unmeasured: uncertain = Uncertainty.propagate, can also be a boundary condition"
  input list<Pointer<Variable>> vars;
  output list<Pointer<Variable>> knowns = {};
  output list<Pointer<Variable>> boundaryConditions = {};
  output list<Pointer<Variable>> exactEquationVars = {};
  output list<Pointer<Variable>> unmeasured = {};
algorithm
  for var in vars loop
    if hasUncertainty(var, Uncertainty.REFINE) then
      knowns := var :: knowns;
    elseif isBoundaryCondition(var) then
      boundaryConditions := var :: boundaryConditions;
    else
      exactEquationVars := var :: exactEquationVars;
    end if;
    if hasUncertainty(var, Uncertainty.PROPAGATE) then
      unmeasured := var :: unmeasured;
    end if;
  end for;
  knowns := listReverse(knowns);
  boundaryConditions := listReverse(boundaryConditions);
  exactEquationVars := listReverse(exactEquationVars);
  unmeasured := listReverse(unmeasured);
end getVariableCategories;

protected function hasUncertainty
  input Pointer<Variable> var_ptr;
  input Uncertainty uncertainty;
  output Boolean b;
protected
  Variable var = Pointer.access(var_ptr);
algorithm
  b := match BackendExtension.VariableAttributes.getUncertainty(var.backendinfo.attributes)
    local
      Uncertainty u;
    case SOME(u) then u == uncertainty;
    else false;
  end match;
end hasUncertainty;

protected function isBoundaryCondition
  input Pointer<Variable> var_ptr;
  output Boolean b;
protected
  Variable var = Pointer.access(var_ptr);
algorithm
  b := SCodeUtil.commentHasBooleanNamedAnnotation(var.comment, "__OpenModelica_BoundaryCondition");
end isBoundaryCondition;

protected function isBindingComponent
  "binding equations are created by NBBindings with the residual name $RES_BND_<n>"
  input StrongComponent comp;
  output Boolean b;
algorithm
  b := match comp
    case StrongComponent.SINGLE_COMPONENT()
    then StringUtil.startsWith(ComponentRef.firstName(Equation.getEqnName(comp.eqn)), NBVariable.RESIDUAL_STR + "_BND_");
    else false;
  end match;
end isBindingComponent;

protected function dumpComponents
  input list<StrongComponent> comps;
  input String heading;
protected
  Integer i = 1;
algorithm
  print(heading + ":(" + intString(listLength(comps)) + ")
" + "============================================================

");
  for comp in comps loop
    print(intString(i) + ": " + componentString(comp) + "
");
    i := i + 1;
  end for;
  print("
");
end dumpComponents;

protected function componentString
  input StrongComponent comp;
  output String str;
algorithm
  str := match comp
    case StrongComponent.SINGLE_COMPONENT()
    then ComponentRef.toString(BVariable.getVarName(comp.var)) + ": " + Equation.toString(Pointer.access(comp.eqn));
    else StrongComponent.toString(comp);
  end match;
end componentString;

protected function dumpVarList
  input list<Pointer<Variable>> vars;
  input String heading;
protected
  Integer i = 1;
algorithm
  print(heading + " (" + intString(listLength(vars)) + ")\n========================================\n");
  for var in vars loop
    print(intString(i) + ": " + BVariable.pointerToString(var) + "\n");
    i := i + 1;
  end for;
  print("\n\n");
end dumpVarList;

annotation(__OpenModelica_Interface="nbackend");
end NBDataReconciliation;
