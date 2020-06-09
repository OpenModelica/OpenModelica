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
encapsulated package NBCausalize
"file:        NBCausalize.mo
 package:     NBCausalize
 description: This file contains the functions which perform the causalization process;
"

public
  import Module = NBModule;

protected
  // NF imports
  import Variable = NFVariable;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import BVariable = NBVariable;
  import Equation = NBEquation.Equation;
  import StrongComponent = NBStrongComponent;
  import System = NBSystem;

public
  function main extends Module.wrapper;
    input System.SystemType systemType;
  algorithm
    bdae := match (systemType, bdae)
      local
        BackendDAE.BackendDAE qual;
        list<System.System> systems;

      case (System.SystemType.ODE, qual as BackendDAE.BDAE(ode = systems))
        algorithm
          // ToDo: For now everything is DAE-Mode, change later on!
          qual.ode := List.map(systems, causalizeDAEMode);
      then qual;

      case (System.SystemType.INIT, qual as BackendDAE.BDAE(init = systems))
        algorithm
          // ToDo: For now everything is DAE-Mode, change later on!
          qual.init := List.map(systems, causalizeDAEMode);
      then qual;

      case (System.SystemType.DAE, qual as BackendDAE.BDAE(dae = SOME(systems)))
        algorithm
          qual.dae := SOME(List.map(systems, causalizeDAEMode));
      then qual;

    else algorithm
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed with system type " + System.System.systemTypeString(systemType) + "!"});
    then fail();

    end match;
  end main;

protected
  function causalizeDAEMode
    input output System.System system;
  protected
    list<Pointer<Variable>> var_lst;
    list<Pointer<Equation>> eqn_lst;
    StrongComponent comp;
  algorithm
    // For now only create one block containing everything
    var_lst := BVariable.VariablePointers.toList(system.unknowns);
    eqn_lst := BEquation.EquationPointers.toList(system.equations);
    comp := StrongComponent.ALGEBRAIC_LOOP(var_lst, eqn_lst, NONE(), false);
    system.strongComponents := SOME(arrayCreate(1, comp));
  end causalizeDAEMode;

  annotation(__OpenModelica_Interface="backend");
end NBCausalize;
