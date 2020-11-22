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
"file:        NBackendDAE.mo
 package:     NBackendDAE
 description: This file contains the data-types used by the back end.
"

protected

  // New Frontend imports
  import BackendExtension = NFBackendExtension;
  import ComponentRef = NFComponentRef;
  import ConvertDAE = NFConvertDAE;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import FEquation = NFEquation;
  import FlatModel = NFFlatModel;
  import InstNode = NFInstNode.InstNode;
  import NFFlatten.FunctionTree;
  import Prefixes = NFPrefixes;
  import Type = NFType;
  import Variable = NFVariable;

  // New Backend imports
  import BackendDAE = NBackendDAE;
  import BVariable = NBVariable;
  import BEquation = NBEquation;
  import Equation = NBEquation.Equation;

  // Util imports
  import Error;
  import StringUtil;

public
  record BDAE
    /* Stuff here! */
    BVariable.VarData varData  "Variable data.";
    BEquation.Equations equations   "All equations";
  end BDAE;

  function toString
    input BackendDAE bdae;
    input output String str = "";
  algorithm
    str := StringUtil.headline_1("BackendDAE: " + str) + "\n" +
          BVariable.VarData.toString(bdae.varData) + "\n" +
          BEquation.Equation.equationsToString(bdae.equations);
  end toString;

  public function lower
    "This function transforms the FlatModel structure to BackendDAE."
    input FlatModel flatModel;
    input FunctionTree funcTree;
    output BackendDAE bdae;
  protected
    BVariable.VarData variableData;
    BEquation.Equations equations;
  algorithm
    //print(FlatModel.toString(flatModel, true));
    variableData := lowerVariableData(flatModel.variables);
    equations := lowerEquations(flatModel.equations);
    bdae := BDAE(variableData, equations);
  end lower;

protected
  function lowerVariableData
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
    stateOrder := BVariable.NO_STATE_ORDER();
    // sort vars to have sorting independent heuristic behaviours
    // ToDo! kabdelhak: use already existing hash values for this?

    // routine to prepare the lists for pointer arrays
    for var in varList loop
      lowVar := lowerVariable(var);
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
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{"NBackendDAE.lowerVariableData failed for " + Variable.toString(var)});
      then fail();

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

  function lowerVariable
    input output Variable var;
  protected
    Option<DAE.VariableAttributes> attributes;
    BackendExtension.VariableKind varKind;
  algorithm
    // ToDo! extract tearing select option
    try
      attributes := ConvertDAE.convertVarAttributes(var.typeAttributes, var.ty, var.attributes);
      varKind := lowerVariableKind(Variable.variability(var), attributes, var.ty);
      var.backendinfo := BackendExtension.BACKEND_INFO(varKind, attributes, NONE());
    else
      Error.addMessage(Error.INTERNAL_ERROR,{"NBackendDAE.lowerVariable failed for " + Variable.toString(var)});
      fail();
    end try;
  end lowerVariable;

  function lowerVariableKind
    "ToDo: Merge this part from old backend conversion:
      /* Consider toplevel inputs as known unless they are protected. Ticket #5591 */
      false := DAEUtil.topLevelInput(inComponentRef, inVarDirection, inConnectorType, protection);"
    input Prefixes.Variability variability;
    input Option<DAE.VariableAttributes> attributes;
    input Type ty;
    output BackendExtension.VariableKind varKind;
  algorithm
    varKind := match(variability, attributes, ty)

      // variable -> artificial state if it has stateSelect = StateSelect.always
      case (NFPrefixes.Variability.CONTINUOUS, SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.ALWAYS()))), _)
        guard(variability == NFPrefixes.Variability.CONTINUOUS)
        then BackendExtension.STATE(1, NONE(), false);

      // variable -> artificial state if it has stateSelect = StateSelect.prefer
      /* I WANT TO REMOVE THIS AND CATCH IT PROPERLY IN STATE SELECTION!
      case (Prefixes.Variability.CONTINUOUS(), SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.PREFER()))))
        then BackendExtension.STATE(1, NONE(), false);
      */

      // is this just a hack? Do we need those cases, or do we need even more?
      case (NFPrefixes.Variability.CONTINUOUS, _, Type.BOOLEAN())     then BackendExtension.DISCRETE();
      case (NFPrefixes.Variability.CONTINUOUS, _, Type.INTEGER())     then BackendExtension.DISCRETE();
      case (NFPrefixes.Variability.CONTINUOUS, _, Type.ENUMERATION()) then BackendExtension.DISCRETE();
      case (NFPrefixes.Variability.CONTINUOUS, _, _)                  then BackendExtension.ALGEBRAIC();

      case (NFPrefixes.Variability.DISCRETE, _, _)                    then BackendExtension.DISCRETE();
      case (NFPrefixes.Variability.IMPLICITLY_DISCRETE, _, _)         then BackendExtension.DISCRETE();

      case (NFPrefixes.Variability.PARAMETER, _, _)                   then BackendExtension.PARAMETER();
      case (NFPrefixes.Variability.STRUCTURAL_PARAMETER, _, _)        then BackendExtension.PARAMETER();
      case (NFPrefixes.Variability.NON_STRUCTURAL_PARAMETER, _, _)    then BackendExtension.PARAMETER();
      case (NFPrefixes.Variability.CONSTANT, _, _)                    then BackendExtension.CONSTANT();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{"NBackendDAE.lowerVariableKind failed."});
      then fail();
    end match;
  end lowerVariableKind;

  protected function lowerEquations
    "ToDo! and algorithms
    ToDo! Replace instNode in all Crefs"
    input list<FEquation> eq_lst;
    output BEquation.Equations equations;
  protected
    Integer index = 1;
    list<Equation> backend_equations;
  algorithm
  equations := ExpandableArray.new(realInt(listLength(eq_lst)*1.4), BEquation.DUMMY_EQUATION());
    for eq in eq_lst loop
      backend_equations := lowerEquation(eq);
      for b_eq in backend_equations loop
        equations := ExpandableArray.set(index, b_eq, equations);
        index := index + 1;
      end for;
    end for;
    ExpandableArray.compress(equations);
  end lowerEquations;

  protected function lowerEquation
    input FEquation frontend_equation;
    output list<Equation> backend_equations;
  algorithm
    backend_equations := match frontend_equation
      local
        list<Equation> result = {}, new_body;
        Expression lhs, rhs, range, e1, e2, e3;
        ComponentRef lhs_cref, rhs_cref;
        list<FEquation> body;
        Type ty;
        DAE.ElementSource source;
        InstNode iterator;
        list<FEquation.Branch> branches;
        BEquation.EquationAttributes attr;

      case FEquation.EQUALITY(lhs = lhs, rhs = rhs, ty = ty, source = source)
        algorithm
          attr := lowerEquationAttributes(ty);
          result := if Type.isComplex(ty) then {BEquation.RECORD_EQUATION(Type.dimensionCount(ty), lhs, rhs, source, attr)}
                                          else {BEquation.SCALAR_EQUATION(lhs, rhs, source, attr)};
      then result;

      case FEquation.CREF_EQUALITY(lhs = lhs_cref as NFComponentRef.CREF(ty = ty), rhs = rhs_cref, source = source)
        algorithm
          attr := lowerEquationAttributes(ty);
          // No check for complex. Simple equation is more important than complex. -> alias removal!
      then {BEquation.SIMPLE_EQUATION(lhs_cref, rhs_cref, source, attr)};

      case FEquation.ARRAY_EQUALITY(lhs = lhs, rhs = rhs, ty = ty as Type.ARRAY(), source = source)
        algorithm
          attr := lowerEquationAttributes(Type.arrayElementType(ty));
          //ToDo! How to get Record size and replace NONE()?
      then {BEquation.ARRAY_EQUATION(List.map(ty.dimensions, Dimension.size), lhs, rhs, source, attr, NONE())};

      case FEquation.FOR(iterator = iterator, range = SOME(range), body = body, source = source)
        algorithm
        // Treat each body equation individually because they can have different equation attributes
        // E.g.: DISCRETE, EvalStages
        for eq in body loop
          new_body := lowerEquation(eq);
          for body_elem in new_body loop
            result := BEquation.FOR_EQUATION(iterator, range, body_elem, source, Equation.getAttributes(body_elem)) :: result;
          end for;
        end for;
      then result;

      case FEquation.IF(branches = branches, source = source)
        algorithm
          // ToDo! split up the body equations with simplify if equations
          // ToDo! inherit findZeroCrossings
      then {BEquation.DUMMY_EQUATION()};

      case FEquation.WHEN(branches = branches, source = source)
          // ToDo! inherit findZeroCrossings
      then {BEquation.DUMMY_EQUATION()};

      case FEquation.ASSERT(condition = e1, message = e2, level = e3, source = source)
          // ToDo! inherit findZeroCrossings
      then {BEquation.DUMMY_EQUATION()};

      case FEquation.TERMINATE(message = e1, source = source)
          // ToDo! inherit findZeroCrossings
      then {BEquation.DUMMY_EQUATION()};

      case FEquation.REINIT(cref = e1, reinitExp = e2, source = source)
          // ToDo! inherit findZeroCrossings
      then {BEquation.DUMMY_EQUATION()};

      case FEquation.NORETCALL(exp = e1, source = source)
          // ToDo! inherit findZeroCrossings
      then {BEquation.DUMMY_EQUATION()};

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{"NBackendDAE.lowerEquation failed for " + FEquation.toString(frontend_equation)});
      then fail();

    end match;
  end lowerEquation;

  protected function lowerEquationAttributes
    input Type ty;
    output BEquation.EquationAttributes attr;
  algorithm
    attr := if Type.isDiscrete(ty) then NBEquation.EQ_ATTR_DEFAULT_DISCRETE else NBEquation.EQ_ATTR_DEFAULT_DYNAMIC;
  end lowerEquationAttributes;

  annotation(__OpenModelica_Interface="backend");
end NBackendDAE;
