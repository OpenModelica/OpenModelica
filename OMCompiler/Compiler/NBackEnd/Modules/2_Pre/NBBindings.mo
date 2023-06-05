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
encapsulated package NBBindings
" file:         NBBindings.mo
  package:      NBBindings
  description:  Creates binding equation for all bound continous variables.
"

protected
  import Module = NBModule;

  import BackendDAE = NBackendDAE;
  import NBEquation.{Equation, EquationPointers, EqData};
  import Variable = NFVariable;
  import BVariable = NBVariable;
  import NBVariable.{VariablePointers, VarData};

public
  function main extends Module.wrapper;
  algorithm
    bdae := match bdae
      local
        VarData varData                             "Data containing variable pointers";
        EqData eqData                               "Data containing equation pointers";
        list<Pointer<Variable>> bound_vars          "list of bound unknown variables";
        list<Pointer<Equation>> binding_cont = {}   "list of created continuous binding equations";
        list<Pointer<Equation>> binding_disc = {}   "list of created discrete binding equations";

      case BackendDAE.MAIN(varData = varData as VarData.VAR_DATA_SIM(), eqData = eqData as EqData.EQ_DATA_SIM())
      algorithm
        bound_vars := list(var for var guard(BVariable.isBound(var)) in VariablePointers.toList(varData.unknowns));
        for var in bound_vars loop
          if BVariable.isContinuous(var) then
            binding_cont := Equation.generateBindingEquation(var, eqData.uniqueIndex, false) :: binding_cont;
          else
            binding_disc := Equation.generateBindingEquation(var, eqData.uniqueIndex, false) :: binding_disc;
          end if;
        end for;

        // adding all continuous equations
        eqData.equations  := EquationPointers.addList(binding_cont, eqData.equations);
        eqData.simulation := EquationPointers.addList(binding_cont, eqData.simulation);
        eqData.continuous := EquationPointers.addList(binding_cont, eqData.continuous);

        // adding all discrete equations
        eqData.equations  := EquationPointers.addList(binding_disc, eqData.equations);
        eqData.simulation := EquationPointers.addList(binding_disc, eqData.simulation);
        eqData.discretes  := EquationPointers.addList(binding_disc, eqData.discretes);

        bdae.eqData := eqData;

        if Flags.isSet(Flags.DUMP_BINDINGS) then
          print(List.toString(binding_cont, function Equation.pointerToString(str = ""), StringUtil.headline_4("Created Continuous Binding Equations:"), "\t", "\n\t", "", false) + "\n\n");
          print(List.toString(binding_disc, function Equation.pointerToString(str = ""), StringUtil.headline_4("Created Discrete Binding Equations:"), "\t", "\n\t", "", false) + "\n\n");
        end if;

      then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
      then fail();
    end match;
  end main;

  annotation(__OpenModelica_Interface="backend");
end NBBindings;


