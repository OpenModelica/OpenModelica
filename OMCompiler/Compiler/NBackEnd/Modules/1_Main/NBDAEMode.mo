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
  import Causalize = NBCausalize;
  import NBEquation.{Equation, EquationPointers, EqData, Iterator};
  import Inline = NBInline;
  import Jacobian = NBJacobian;
  import Partition = NBPartition;
  import StrongComponent = NBStrongComponent;
  import Tearing = NBTearing;
  import BVariable = NBVariable;
  import NBVariable.{VariablePointer, VariablePointers, VarData};

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
          list<Partition.Partition> ode;
          EqData eqData;
          VariablePointers variables;

        case BackendDAE.MAIN(ode = ode, eqData = eqData as EqData.EQ_DATA_SIM(), varData = VarData.VAR_DATA_SIM(variables = variables))
          algorithm
            bdae.dae := SOME(func(ode, variables, eqData.uniqueIndex));
        then bdae;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed due to wrong BackendDAE record!"});
        then fail();
      end match;

      // fake causalize system to fulfill pipeline requirements
      bdae := Causalize.main(bdae, NBPartition.Kind.DAE);
    else
      Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
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
    list<Partition.Partition> new_partitions = {};
    Pointer<list<Pointer<Equation>>> new_eqns;
    UnorderedSet<VariablePointer> dummy_set = UnorderedSet.new(BVariable.hash, BVariable.equalName);
  algorithm
    for part in partitions loop
      new_partitions := match part.association
        local
          Partition.Association association;
          Option<array<StrongComponent>> new_comps;

        case association as Partition.Association.CONTINUOUS() algorithm
          // update association to continuous -> dae
          association.kind := NBPartition.Kind.DAE;
          part.association := association;

          // get the new components
          new_comps := StrongComponent.sortDAEModeComponents(part.strongComponents, variables, uniqueIndex);
          // Todo: get proper equations from strong components, still old are saved
          // get new unknowns


          // accumulate new partitions
        then if Partition.Partition.isEmpty(part) then new_partitions else part :: new_partitions;

        else new_partitions;
      end match;
    end for;
    partitions := listReverse(new_partitions);
  end daeModeDefault;

  annotation(__OpenModelica_Interface="backend");
end NBDAEMode;