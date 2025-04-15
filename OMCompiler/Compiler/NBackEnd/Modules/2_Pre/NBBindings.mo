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
  import NBVariable.{VariablePointers, VariablePointer, VarData};

  // Util
  import StringUtil;

public
  function main extends Module.wrapper;
  algorithm
    bdae := match bdae
      local
        VarData varData                             "Data containing variable pointers";
        EqData eqData                               "Data containing equation pointers";
        list<Pointer<Variable>> bound_vars          "list of bound unknown variables";
        list<Pointer<Variable>> bound_clocks        "list of bound clock variables";
        list<Pointer<Equation>> binding_cont = {}   "list of created continuous binding equations";
        list<Pointer<Equation>> binding_clck = {}   "list of created clocked binding equations";
        list<Pointer<Equation>> binding_disc = {}   "list of created discrete binding equations";
        list<Pointer<Equation>> binding_rec = {}    "list of created record binding equations";
        Pointer<Variable> parent                    "optional record parent";
        Boolean skip_record_element                 "true if this variable is part of an array and the array variable is bound";
        UnorderedSet<VariablePointer> new_iters = UnorderedSet.new(BVariable.hash, BVariable.equalName);

      case BackendDAE.MAIN(varData = varData as VarData.VAR_DATA_SIM(), eqData = eqData as EqData.EQ_DATA_SIM())
      algorithm
        // create continuous and discrete binding equations
        bound_vars := list(var for var guard(BVariable.isBound(var)) in VariablePointers.toList(varData.unknowns));
        for var in bound_vars loop
          // do not create bindings for record children with bound parents! they are bound off their record variables
          // if the parent is not fully unkown also create individual bindings
          skip_record_element := match BVariable.getParent(var)
            case SOME(parent) then BVariable.isBound(parent) and BVariable.isUnknownRecord(parent);
            else false;
          end match;

          if not skip_record_element then
            if BVariable.isContinuous(var, false) then
              binding_cont := Equation.generateBindingEquation(var, eqData.uniqueIndex, false, new_iters) :: binding_cont;
            else
              binding_disc := Equation.generateBindingEquation(var, eqData.uniqueIndex, false, new_iters) :: binding_disc;
            end if;
          end if;
        end for;

        // create record binding equations, but only for unknown records
        // known record binding equations will be created for initialization
        bound_vars := list(var for var guard(BVariable.isBound(var) and BVariable.isUnknownRecord(var)) in VariablePointers.toList(varData.records));
        for var in bound_vars loop
          binding_rec := Equation.generateBindingEquation(var, eqData.uniqueIndex, false, new_iters) :: binding_rec;
        end for;

        // create clock bindings
        bound_clocks := list(var for var guard(BVariable.isBound(var)) in VariablePointers.toList(varData.clocks));
        for var in bound_clocks loop
          binding_clck := Equation.generateBindingEquation(var, eqData.uniqueIndex, false, new_iters) :: binding_clck;
        end for;

        // adding all continuous equations
        eqData.equations  := EquationPointers.addList(binding_cont, eqData.equations);
        eqData.simulation := EquationPointers.addList(binding_cont, eqData.simulation);
        eqData.continuous := EquationPointers.addList(binding_cont, eqData.continuous);

        // adding all discrete equations
        eqData.equations  := EquationPointers.addList(binding_disc, eqData.equations);
        eqData.simulation := EquationPointers.addList(binding_disc, eqData.simulation);
        eqData.discretes  := EquationPointers.addList(binding_disc, eqData.discretes);

        // adding all record equations
        eqData.equations  := EquationPointers.addList(binding_rec, eqData.equations);
        eqData.simulation := EquationPointers.addList(binding_rec, eqData.simulation);
        eqData.continuous := EquationPointers.addList(binding_rec, eqData.continuous);

        // adding all clocked equations
        eqData.clocked    := EquationPointers.addList(binding_clck, eqData.clocked);

        bdae.eqData := eqData;

        bdae.varData := VarData.addTypedList(bdae.varData, UnorderedSet.toList(new_iters), NBVariable.VarData.VarType.ITERATOR);

        if Flags.isSet(Flags.DUMP_BACKENDDAE_INFO) then
          Error.addSourceMessage(Error.BACKENDDAEINFO_LOWER,{
            intString(EqData.scalarSize(eqData)) + " (" + intString(EqData.size(eqData)) + ")",
            intString(VarData.scalarSize(varData)) + " (" + intString(VarData.size(varData)) + ")"},
            AbsynUtil.dummyInfo);
        end if;

        if Flags.isSet(Flags.DUMP_BINDINGS) then
          print(List.toString(binding_cont, function Equation.pointerToString(str = "\t"),
            StringUtil.headline_4("Created Continuous Binding Equations (" + intString(listLength(binding_cont)) + "):"), "", "\n", "", false) + "\n\n");
          print(List.toString(binding_clck, function Equation.pointerToString(str = "\t"),
            StringUtil.headline_4("Created Clocked Binding Equations (" + intString(listLength(binding_clck)) + "):"), "", "\n", "", false) + "\n\n");
          print(List.toString(binding_disc, function Equation.pointerToString(str = "\t"),
            StringUtil.headline_4("Created Discrete Binding Equations (" + intString(listLength(binding_disc)) + "):"), "", "\n", "", false) + "\n\n");
          print(List.toString(binding_rec, function Equation.pointerToString(str = "\t"),
            StringUtil.headline_4("Created Record Binding Equations (" + intString(listLength(binding_rec)) + "):"), "", "\n", "", false) + "\n\n");
        end if;

      then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
      then fail();
    end match;
  end main;

  annotation(__OpenModelica_Interface="backend");
end NBBindings;


