/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
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
encapsulated uniontype NBTearing
"file:        NBTearing.mo
 package:     NBTearing
 description: This file contains the data-types used for tearing. It is a
              uniontype and therefore also contains some structures for tearing.
"

public
  import BackendDAE = NBackendDAE;
  import Module = NBModule;

protected
  // selfimport
  import Tearing = NBTearing;

  // NF imports
  import NFFlatten.FunctionTree;
  import Variable = NFVariable;

  // Backend imports
  import BEquation = NBEquation;
  import BJacobian = NBJacobian;
  import Differentiate = NBDifferentiate;
  import NBEquation.Equation;
  import NBEquation.EquationPointers;
  import NBEquation.InnerEquation;
  import Jacobian = NBackendDAE.BackendDAE;
  import StrongComponent = NBStrongComponent;
  import System = NBSystem;
  import NBVariable.VariablePointers;

  //Util imports
  import StringUtil;

public
  record TEARING_SET
    list<Pointer<Variable>> iteration_vars    "the variables used for iteration";
    list<Pointer<Equation>> residual_eqns     "implicitely solved residual equations";
    array<InnerEquation> innerEquations       "list of matched equations and variables";
    Option<Jacobian> jac                      "optional jacobian";
  end TEARING_SET;

  function toString
    input Tearing set;
    input output String str;
  algorithm
    str := StringUtil.headline_4(str);
    str := str + "### Iteration Variables:\n";
    for var in set.iteration_vars loop
      str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
    end for;
    str := str + "\n### Residual Equations:\n";
    for eqn in set.residual_eqns loop
      str := str  + Equation.toString(Pointer.access(eqn), "\t") + "\n";
    end for;
    // ToDo: inner equations and jacobian
    if Util.isSome(set.jac) then
      str := str + "\n" + BJacobian.toString(Util.getOption(set.jac), "NLS", true);
    end if;
  end toString;

  function main
    "Wrapper function for any tearing function. This will be
    called during simulation and gets the corresponding subfunction from
    Config."
    extends Module.wrapper;
    input System.SystemType systemType;
  protected
    constant Module.tearingInterface func = getModule();
    FunctionTree funcTree;
  algorithm
    bdae := match (systemType, bdae)
      local
        list<System.System> systems;

      case (NBSystem.SystemType.ODE, BackendDAE.MAIN(ode = systems, funcTree = funcTree))
        algorithm
          (systems, funcTree) := tearingTraverser(systems, func, funcTree);
          bdae.ode := systems;
      then bdae;

      case (NBSystem.SystemType.INIT, BackendDAE.MAIN(init = systems, funcTree = funcTree))
        algorithm
          (systems, funcTree) := tearingTraverser(systems, func, funcTree);
          bdae.init := systems;
      then bdae;

      case (NBSystem.SystemType.DAE, BackendDAE.MAIN(dae = SOME(systems), funcTree = funcTree))
        algorithm
          (systems, funcTree) := tearingTraverser(systems, func, funcTree);
          bdae.dae := SOME(systems);
      then bdae;

    // ToDo: all the other cases: e.g. Jacobian, Hessian
    end match;
  end main;

  function getModule
    "Returns the module function that was chosen by the user."
    output Module.tearingInterface func;
  protected
    String flag = "none"; //Flags.getConfigString(Flags.JACOBIAN)
  algorithm
    (func) := match flag
      case "none" then (tearingNone);
      /* ... New tearing modules have to be added here */
      else fail();
    end match;
  end getModule;

protected
  // Traverser function
  function tearingTraverser
    input list<System.System> systems;
    input Module.tearingInterface func;
    output list<System.System> new_systems = {};
    input output FunctionTree funcTree;
  protected
    array<StrongComponent> strongComponents;
    StrongComponent tmp;
    Integer idx = 0;
  algorithm
    for syst in systems loop
      if isSome(syst.strongComponents) then
        SOME(strongComponents) := syst.strongComponents;
        for i in 1:arrayLength(strongComponents) loop
          (tmp, funcTree, idx) := func(strongComponents[i], funcTree, idx);
          // only update if it changed
          if not referenceEq(tmp, strongComponents[i]) then
            arrayUpdate(strongComponents, i, tmp);
          end if;
        end for;
        syst.strongComponents := SOME(strongComponents);
      end if;
      new_systems := syst :: new_systems;
    end for;
    new_systems := listReverse(new_systems);
  end tearingTraverser;

  // Module body functions
  function tearingNone extends Module.tearingInterface;
  algorithm
    comp := match comp
      local
        StrongComponent result;
        String name;
        list<Pointer<Equation>> new_eqns;
        Option<Jacobian> jacobian;
        Tearing tearingSet;
        InnerEquation dummy;

      // apply tearing if it is an algebraic loop
      case StrongComponent.ALGEBRAIC_LOOP()
        algorithm
          // for now do not apply tearing
          index := index + 1;
          name := "JAC" + intString(index);
          dummy := BEquation.INNER_EQUATION(Pointer.create(Equation.DUMMY_EQUATION()), {});
          tearingSet := TEARING_SET(comp.vars, comp.eqns, arrayCreate(0, dummy), NONE());
          result := StrongComponent.TORN_LOOP(index, tearingSet, NONE(), false, comp.mixed);

          (jacobian, funcTree) := BJacobian.simple(
            variables = VariablePointers.fromList(comp.vars),
            equations = EquationPointers.fromList(comp.eqns),
            comp      = result,
            funcTree  = funcTree,
            name      = name
          );

      then StrongComponent.addLoopJacobian(result, jacobian);

      // do nothing otherwise
      else comp;
    end match;
  end tearingNone;

  annotation(__OpenModelica_Interface="backend");
end NBTearing;
