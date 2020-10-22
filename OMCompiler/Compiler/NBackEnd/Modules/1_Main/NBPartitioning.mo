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
encapsulated package NBPartitioning
"file:        NBPartitioning.mo
 package:     NBPartitioning
 description: This file contains the functions for the partitioning module.
"

public
  import Module = NBModule;

protected
  // Backend
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import NBEquation.Equation;
  import NBEquation.EquationPointers;
  import StrongComponent = NBStrongComponent;
  import System = NBSystem;
  import BVariable = NBVariable;
  import NBVariable.VariablePointers;

  // Util
  import DoubleEnded;

// =========================================================================
//                      MAIN ROUTINE, PLEASE DO NOT CHANGE
// =========================================================================
public
  function main
    "Wrapper function for any partitioning function. This will be
     called during simulation and gets the corresponding subfunction from
     Config."
    extends Module.wrapper;
    input System.SystemType systemType;
  protected
    Module.partitioningInterface func;
  algorithm
    func := getModule();

    bdae := match (systemType, bdae)
      local
        VariablePointers variables;
        EquationPointers equations;

      case (System.SystemType.ODE, BackendDAE.MAIN(varData = BVariable.VAR_DATA_SIM(unknowns = variables), eqData = BEquation.EQ_DATA_SIM(simulation = equations)))
        algorithm
          variables := VariablePointers.clone(variables);
          equations := EquationPointers.clone(equations);
          bdae.ode := func(systemType, variables, equations);
        then bdae;

      case (System.SystemType.INI, BackendDAE.MAIN(varData = BVariable.VAR_DATA_SIM(initials = variables), eqData = BEquation.EQ_DATA_SIM(equations = equations)))
        algorithm
          variables := VariablePointers.clone(variables);
          equations := EquationPointers.clone(equations);
          // remove the when equations for initial systems
          equations := EquationPointers.mapRemovePtr(equations, Equation.isWhenEquation);
          bdae.init := func(systemType, variables, equations);
        then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
      then fail();
    end match;
  end main;

  function getModule
    "Returns the module function that was chosen by the user."
    output Module.partitioningInterface func;
  protected
    String flag = "default"; //Flags.getConfigString(Flags.PARTITIONING)
  algorithm
    (func) := match flag
      case "default" then (partitioningDefault);
      /* ... New detect states modules have to be added here */
      else fail();
    end match;
  end getModule;

  function splitSystems
    "creates ODE, ALG, ODE_EVT, ALG_EVT systems from ODE by checking
    if it contains discrete equations or state equations.
    Should be evoked just before jacobian at the very end."
    extends Module.wrapper;
  algorithm
    bdae := match bdae
      local
        DoubleEnded.MutableList<System.System> ode = DoubleEnded.MutableList.fromList({});
        DoubleEnded.MutableList<System.System> alg = DoubleEnded.MutableList.fromList({});
        DoubleEnded.MutableList<System.System> ode_evt = DoubleEnded.MutableList.fromList({});
        DoubleEnded.MutableList<System.System> alg_evt = DoubleEnded.MutableList.fromList({});

      case BackendDAE.MAIN() algorithm
        for syst in bdae.ode loop
          System.System.categorize(syst, ode, alg, ode_evt, alg_evt);
        end for;
        bdae.ode := DoubleEnded.MutableList.toListAndClear(ode);
        bdae.algebraic := DoubleEnded.MutableList.toListAndClear(alg);
        bdae.ode_event := DoubleEnded.MutableList.toListAndClear(ode_evt);
        bdae.alg_event := DoubleEnded.MutableList.toListAndClear(alg_evt);
      then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
      then fail();
    end match;
  end splitSystems;

protected
  function partitioningDefault extends Module.partitioningInterface;
  algorithm
    // ToDo: actually do partitioning! For now just create one system with everything inside.
    systems := {System.SYSTEM(systemType, variables, NONE(), equations, NONE(), NONE(), NONE(), System.PartitionKind.UNKNOWN, NONE(), NONE())};
  end partitioningDefault;

annotation(__OpenModelica_Interface="backend");
end NBPartitioning;
