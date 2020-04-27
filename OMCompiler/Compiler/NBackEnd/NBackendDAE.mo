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
  import Algorithm = NFAlgorithm;
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
  import IOStream;

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
          BVariable.VarData.toString(bdae.varData, 1) + "\n" +
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
    equations := lowerEquationsAndAlgorithms(flatModel.equations, flatModel.algorithms, variableData);
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

      // Remove old type attribute information since it has been converted.
      var.typeAttributes := {};
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

  function lowerEquationsAndAlgorithms
    "ToDo! Replace instNode in all Crefs
    Converts all frontend equations and algorithms to backend equations.
    Also needs the variables, because it replaces all InstNodes with
    VariablePointers for the Backend."
    input list<FEquation> eq_lst;
    input list<Algorithm> al_lst;
    input BVariable.VarData varData;
    output BEquation.Equations equations;
  protected
    Integer index = 1;
    Integer arraySize;
    list<Equation> backend_equations;
  algorithm
    arraySize := realInt((listLength(eq_lst) + listLength(al_lst))*1.4);
    equations := ExpandableArray.new(arraySize, BEquation.DUMMY_EQUATION());

    // convert all equations
    for eq in eq_lst loop
      // returns a list of equations since for and if equations might be split up
      backend_equations := lowerEquation(eq, varData);
      for b_eq in backend_equations loop
        equations := ExpandableArray.set(index, b_eq, equations);
        index := index + 1;
      end for;
    end for;

    // convert all algorithms
    for alg in al_lst loop
      equations := ExpandableArray.set(index, lowerAlgorithm(alg), equations);
      index := index + 1;
    end for;

    ExpandableArray.compress(equations);
  end lowerEquationsAndAlgorithms;

  function lowerEquation
    input FEquation frontend_equation;
    input BVariable.VarData varData;
    output list<Equation> backend_equations;
  algorithm
    backend_equations := match frontend_equation
      local
        list<Equation> result = {}, new_body;
        Expression lhs, rhs, range;
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
          new_body := lowerEquation(eq, varData);
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

      // When equation cases
      case FEquation.WHEN()       then {lowerWhenEquation(frontend_equation)};
      case FEquation.ASSERT()     then {lowerWhenEquation(frontend_equation)};

      // These have to be called inside a when equation body since they need
      // to get passed a condition from surrounding when equation.
      case FEquation.TERMINATE() algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{"NBackendDAE.lowerEquation failed for TERMINATE expression without condition:\n" + FEquation.toString(frontend_equation)});
      then fail();
      case FEquation.REINIT() algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{"NBackendDAE.lowerEquation failed for REINIT expression without condition:\n" + FEquation.toString(frontend_equation)});
      then fail();
      case FEquation.NORETCALL() algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{"NBackendDAE.lowerEquation failed for NORETCALL expression without condition:\n" + FEquation.toString(frontend_equation)});
      then fail();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{"NBackendDAE.lowerEquation failed for " + FEquation.toString(frontend_equation)});
      then fail();

    end match;
  end lowerEquation;

  function lowerWhenEquation
    // ToDo! inherit findZeroCrossings or implement own routine to be applied after lowering
    input FEquation frontend_equation;
    output Equation backend_equation;
  algorithm
    backend_equation := match frontend_equation
      local
        list<FEquation.Branch> branches;
        DAE.ElementSource source;
        Expression condition, message, level;
        BEquation.WhenEquationBody whenEqBody, elseWhenEq;

      case FEquation.WHEN(branches = branches, source = source)
        algorithm
          SOME(whenEqBody) := lowerWhenEquationBody(branches);
      then BEquation.WHEN_EQUATION(0, whenEqBody, source, NBEquation.EQ_ATTR_DEFAULT_DISCRETE);

      case FEquation.ASSERT(condition = condition, message = message, level = level, source = source)
        algorithm
          whenEqBody := BEquation.WHEN_EQUATION_BODY(condition, {BEquation.ASSERT(condition, message, level, source)}, NONE());
      then BEquation.WHEN_EQUATION(0, whenEqBody, source, NBEquation.EQ_ATTR_DEFAULT_DISCRETE);

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{"NBackendDAE.lowerWhenEquation failed for " + FEquation.toString(frontend_equation)});
      then fail();

    end match;
  end lowerWhenEquation;

  function lowerWhenEquationBody
    input list<FEquation.Branch> branches;
    output Option<BEquation.WhenEquationBody> whenEq;
  algorithm
    whenEq := match branches
      local
        FEquation.Branch branch;
        list<FEquation.Branch> rest;
        list<BEquation.WhenStatement> stmts;
        Expression condition;

      // End of the line
      case {} then NONE();

      // lower current branch
      case branch::rest
        algorithm
          (stmts, condition) := lowerWhenBranch(branch);
      then SOME(BEquation.WHEN_EQUATION_BODY(condition, stmts, lowerWhenEquationBody(rest)));

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{"NBackendDAE.lowerWhenEquationBody failed."});
      then fail();

    end match;
  end lowerWhenEquationBody;

  function lowerWhenBranch
    input FEquation.Branch branch;
    output list<BEquation.WhenStatement> stmts;
    output Expression cond;
  algorithm
    (stmts, cond) := match branch
      local
        Expression condition;
        list<FEquation.Equation> body;
      case FEquation.BRANCH(condition = condition, body = body)
        // ToDo! Use condition variability here to have proper type of the
        // auxiliary that will be created for the condition.
      then (lowerWhenBranchBody(condition, body), condition);

      case FEquation.INVALID_BRANCH() algorithm
        // what to do with error message from invalid branch? Is that even needed?
        Error.addMessage(Error.INTERNAL_ERROR,{"NBackendDAE.lowerWhenBranch failed for invalid branch that should not exist outside of frontend."});
      then fail();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{"NBackendDAE.lowerWhenBranch failed without proper error message."});
      then fail();

    end match;
  end lowerWhenBranch;

  function lowerWhenBranchBody
    input Expression condition;
    input list<FEquation.Equation> body;
    input output list<BEquation.WhenStatement> stmts = {};
  algorithm
    stmts := match body
      local
        FEquation.Equation elem;
        list<FEquation.Equation> rest;
      case {}         then stmts;
      case elem::rest then lowerWhenBranchBody(condition, rest, lowerWhenBranchStatement(elem, condition) :: stmts);
    end match;
  end lowerWhenBranchBody;

  function lowerWhenBranchStatement
    input FEquation.Equation eq;
    input Expression condition;
    output BEquation.WhenStatement stmt;
  algorithm
    stmt := match eq
      local
        Expression message, exp, lhs, rhs;
        ComponentRef cref, lhs_cref, rhs_cref;
        Type lhs_ty, rhs_ty;
        DAE.ElementSource source;
      // These should hopefully not occur, check assert for same condition?
      // case FEquation.WHEN()       then fail();
      // case FEquation.ASSERT()     then fail();

      // These do not provide their own conditions and are therefore body branches
      case FEquation.TERMINATE(message = message, source = source)
      then BEquation.TERMINATE(message, source);

      case FEquation.REINIT(cref = Expression.CREF(cref = cref), reinitExp = exp, source = source)
      then BEquation.REINIT(cref, exp, source);

      case FEquation.NORETCALL(exp = exp, source = source)
      then BEquation.NORETCALL(exp, source);

      // Convert other equations to assignments
      case FEquation.EQUALITY(lhs = lhs, rhs = rhs, source = source)
      then BEquation.ASSIGN(lhs, rhs, source);

      case FEquation.CREF_EQUALITY(lhs = lhs_cref as NFComponentRef.CREF(ty = lhs_ty), rhs = rhs_cref as NFComponentRef.CREF(ty = rhs_ty), source = source)
      then BEquation.ASSIGN(Expression.CREF(lhs_ty, lhs_cref), Expression.CREF(rhs_ty, rhs_cref), source);

      case FEquation.ARRAY_EQUALITY(lhs = lhs, rhs = rhs, source = source)
      then BEquation.ASSIGN(lhs, rhs, source);

      /* ToDo! implement proper cases for FOR and IF --> need FOR_ASSIGN and IF_ASSIGN ?
      case FEquation.FOR(iterator = iterator, range = SOME(range), body = body, source = source)
      case FEquation.IF(branches = branches, source = source)
      */

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{"NBackendDAE.lowerWhenBranchStatement for " + FEquation.toString(eq)});
      then fail();
    end match;
  end lowerWhenBranchStatement;

  function lowerAlgorithm
    input Algorithm alg;
    output Equation eq;
  protected
    Integer size;
    list<ComponentRef> inputs, outputs;
  algorithm
    // ToDo! check algorithm outputs and inputs if discrete (?)
    // ToDo! Wait until input, output was migrated from OF CheckModel to NF
    // and use it here
    //(inputs, outputs) := Algorithm.getInputsAndOutputs(alg);
    (inputs, outputs) := ({}, {});
    size := listLength(outputs);
    eq := Equation.ALGORITHM(size, alg, inputs, outputs, alg.source, DAE.EXPAND(), NBEquation.EQ_ATTR_DEFAULT_DYNAMIC);
  end lowerAlgorithm;

  function lowerEquationAttributes
    input Type ty;
    output BEquation.EquationAttributes attr;
  algorithm
    attr := if Type.isDiscrete(ty) then NBEquation.EQ_ATTR_DEFAULT_DISCRETE else NBEquation.EQ_ATTR_DEFAULT_DYNAMIC;
  end lowerEquationAttributes;



  annotation(__OpenModelica_Interface="backend");
end NBackendDAE;
