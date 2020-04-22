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
encapsulated uniontype NBackendDAE
" file:        NBackendDAE.mo
 package:     NBackendDAE
 description: This file contains the data-types used by the back end.
"

protected
  import BackendDAE = NBackendDAE;
  import FlatModel = NFFlatModel;
  import NFFlatten.FunctionTree;
  import Variable = NFVariable;
  import BVariable = NBVariable;
  import BackendExtension = NFBackendExtension;

record BDAE
  /* Stuff here! */
  BVariable.VarData VariableData "Variable data.";
end BDAE;

public function lower
  "This function transforms the FlatModel structure to BackendDAE."
  input FlatModel flatModel;
  input FunctionTree funcTree;
  output NBackendDAE bdae;
protected
  BVariable.VarData variableData;
algorithm
  print(FlatModel.toString(flatModel, true));
  variableData := lowerVariableData(flatModel.variables);
  bdae := BDAE(variableData);
end lower;

protected function lowerVariableData
  input list<Variable> varList;
  output BVariable.VarData variableData;
protected
  BVariable.Variables variables;
  Variable lowVar;
  list<Pointer<Variable>> unknowns_lst = {}, knowns_lst = {}, auxiliaries_lst = {}, aliasVars_lst = {};
  list<Pointer<Variable>> states_lst = {}, derivatives_lst = {}, algebraics_lst = {}, discretes_lst = {}, previous_lst = {};
  list<Pointer<Variable>> parameters_lst = {}, constants_lst = {};
  BVariable.VariablePointers unknowns, knowns, auxiliaries, aliasVars;
  BVariable.VariablePointers states, derivatives, algebraics, discretes, previous;
  BVariable.VariablePointers parameters, constants;
  BVariable.StateOrder stateOrder;
algorithm

  // instantiate variable data and stateOrder
  variables := BVariable.emptyVariables(listLength(varList));
  stateOrder := BVariable.STATE_ORDER();

  // sort vars to have sorting independent heuristic behaviours

  // routine to prepare the lists for pointer arrays
  for var in varList loop
    lowVar := lowerVar(var);
    variables := BVariable.addVar(lowVar, variables);
    _ := match lowVar.backendinfo.varKind

      case BackendExtension.ALGEBRAIC() algorithm
        algebraics_lst := Pointer.create(lowVar) :: algebraics_lst;
        unknowns_lst := Pointer.create(lowVar) :: unknowns_lst;
      then ();

      case BackendExtension.STATE() algorithm
        states_lst := Pointer.create(lowVar) :: states_lst;
        knowns_lst := Pointer.create(lowVar) :: knowns_lst;
      then ();

      case BackendExtension.STATE_DER() algorithm
        derivatives_lst := Pointer.create(lowVar) :: derivatives_lst;
        unknowns_lst := Pointer.create(lowVar) :: unknowns_lst;
      then ();

      case BackendExtension.DISCRETE() algorithm
        discretes_lst := Pointer.create(lowVar) :: discretes_lst;
        unknowns_lst := Pointer.create(lowVar) :: unknowns_lst;
      then ();

      case BackendExtension.PREVIOUS() algorithm
        previous_lst := Pointer.create(lowVar) :: previous_lst;
        knowns_lst := Pointer.create(lowVar) :: knowns_lst;
      then ();

      case BackendExtension.PARAMETER() algorithm
        parameters_lst := Pointer.create(lowVar) :: parameters_lst;
        knowns_lst := Pointer.create(lowVar) :: knowns_lst;
      then ();

      case BackendExtension.CONSTANT() algorithm
        constants_lst := Pointer.create(lowVar) :: constants_lst;
        knowns_lst := Pointer.create(lowVar) :: knowns_lst;
      then ();

      /* other cases should not occur up until now */
      else fail();

    end match;
  end for;

  // create pointer arrays
  unknowns := BVariable.fromPointerList(unknowns_lst);
  knowns := BVariable.fromPointerList(knowns_lst);
  auxiliaries := BVariable.fromPointerList(auxiliaries_lst);
  aliasVars := BVariable.fromPointerList(aliasVars_lst);

  states := BVariable.fromPointerList(states_lst);
  derivatives := BVariable.fromPointerList(derivatives_lst);
  algebraics := BVariable.fromPointerList(algebraics_lst);
  discretes := BVariable.fromPointerList(discretes_lst);
  previous := BVariable.fromPointerList(previous_lst);

  parameters := BVariable.fromPointerList(parameters_lst);
  constants := BVariable.fromPointerList(constants_lst);

  /* create variable data */
  variableData := BVariable.VAR_DATA_SIM(variables, unknowns, knowns, auxiliaries, aliasVars,
                  stateOrder, states, derivatives, algebraics, discretes, previous, parameters, constants);
end lowerVariableData;

function lowerVar
  input output Variable var;
algorithm
  /* change varKind here */
end lowerVar;

annotation(__OpenModelica_Interface="backend");
end NBackendDAE;
