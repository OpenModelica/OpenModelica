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
encapsulated package NBJacobian
"file:        NBJacobian.mo
 package:     NBJacobian
 description: This file contains the functions to create and manipulate jacobians.
              The main type is inherited from NBackendDAE.mo
              NOTE: There is no real jacobian type, it is a BackendDAE.
"

public
  import BackendDAE = NBackendDAE;
  import Module = NBModule;

protected
  // NF imports
  import NFFlatten.FunctionTree;

  // Backend imports
  import Differentiate = NBDifferentiate;
  import BEquation = NBEquation;
  import Jacobian = NBackendDAE.BackendDAE;
  import BVariable = NBVariable;
  import System = NBSystem;

public
  function main
    "Wrapper function for any jacobian function. This will be
    called during simulation and gets the corresponding subfunction from
    Config."
    extends Module.wrapper;
  protected
    constant Module.jacobianInterface func = getModule();
  algorithm
    bdae := match bdae
      local
        String Name                               "Name of jacobian";
        BVariable.VariablePointers unknowns       "Variable array of unknowns";
        BEquation.EquationPointers equations      "Equations array";
        BVariable.VariablePointers knowns         "Variable array of knowns"; // is this needed?
        Option<Jacobian> jacobian                 "Resulting jacobian";
        FunctionTree funcTree                     "Function call bodies";
        list<System.System> newSystems = {}       "Equation systems afterwards";
        Integer idx = 1;

      case BackendDAE.BDAE(varData = BVariable.VAR_DATA_SIM(knowns = knowns), funcTree = funcTree)
        algorithm
          for syst in bdae.ode loop
            (jacobian, funcTree) := match syst
              case System.SYSTEM(unknowns = unknowns, equations = equations)
              /* this needs a unique name! */
              then func("SimJac" + intString(idx), unknowns, equations, knowns , funcTree);
            end match;
            syst.jacobian := jacobian;
            newSystems := syst::newSystems;
            idx := idx + 1;
          end for;
        bdae.ode := listReverse(newSystems);
        bdae.funcTree := funcTree;
      then bdae;
    end match;
  end main;

  function getModule
    "Returns the module function that was chosen by the user."
    output Module.jacobianInterface func;
  protected
    String flag = "default"; //Flags.getConfigString(Flags.JACOBIAN)
  algorithm
    (func) := match flag
      case "default" then (jacobianDefault);
      /* ... New jacobian modules have to be added here */
    else fail();
    end match;
  end getModule;
protected

  function jacobianDefault extends Module.jacobianInterface;
  algorithm
    jacobian := NONE();
  end jacobianDefault;


  annotation(__OpenModelica_Interface="backend");
end NBJacobian;
