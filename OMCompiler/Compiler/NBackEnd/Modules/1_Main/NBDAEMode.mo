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
encapsulated package NBDAEMode
"file:        NBDAEMode.mo
 package:     NBDAEMode
 description: This file contains the functions which create the DAE-Mode data.
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
  import Causalize = NBCausalize;
  import Jacobian = NBJacobian;
  import System = NBSystem;
  import Tearing = NBTearing;

public
  function main extends Module.wrapper;
  protected
    Module.daeModeInterface func;
  algorithm
    try
      func := getModule();
      // for now just copy the dae
      bdae := match bdae
        local
          list<System.System> ode;

        case BackendDAE.BDAE(ode = ode)
          algorithm
            bdae.dae := SOME(func(ode));
        then bdae;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed due to wrong BackendDAE record!"});
        then fail();
      end match;

      // Modules
      bdae := Causalize.main(bdae, NBSystem.SystemType.DAE);
      bdae := Tearing.main(bdae, NBSystem.SystemType.DAE);
      bdae := Jacobian.main(bdae, NBSystem.SystemType.DAE);
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
    end try;
  end main;

  function getModule
    "Returns the module function that was chosen by the user."
    output Module.daeModeInterface func;
  protected
    String flag = "default"; //Flags.getConfigString(Flags.DAE_MODE)
  algorithm
    func := match flag
      case "default" then daeModeDefault;
      /* ... New dae mode modules have to be added here */
      else fail();
    end match;
  end getModule;

protected
  function daeModeDefault extends Module.daeModeInterface;
  protected
    list<System.System> new_systems = {};
    Pointer<list<Pointer<Variable>>> residual_vars = Pointer.create({});
    Pointer<Integer> idx = Pointer.create(0);
  algorithm
    for syst in systems loop
      // move unknowns
      syst.daeUnknowns := SOME(syst.unknowns);
      // convert all algebraic variables to algebraic states
      // BVariable.VariablePointers.mapPtr(syst.unknowns, function BVariable.makeAlgStateVar());
      // convert all residual equations to dae residuals
      BEquation.EquationPointers.map(syst.equations, function BEquation.Equation.createResidual(context = "DAE", residual_vars = residual_vars, idx = idx));
      syst.unknowns := BVariable.VariablePointers.fromList(listReverse(Pointer.access(residual_vars)));
      new_systems := syst :: new_systems;
    end for;
    systems := listReverse(new_systems);
  end daeModeDefault;

  annotation(__OpenModelica_Interface="backend");
end NBDAEMode;
