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
  import ComponentRef = NFComponentRef;
  import NFFlatten.FunctionTree;
  import Variable = NFVariable;

  // Backend imports
  import BEquation = NBEquation;
  import BVariable = NBVariable;
  import Differentiate = NBDifferentiate;
  import HashTableCrToCr = NBHashTableCrToCr;
  import Jacobian = NBackendDAE.BackendDAE;
  import System = NBSystem;

  // Util imports
  import AvlSetPath;
  import Util;

public
  function main
    "Wrapper function for any jacobian function. This will be
    called during simulation and gets the corresponding subfunction from
    Config."
    extends Module.wrapper;
    input System.SystemType systemType;
  protected
    constant Module.jacobianInterface func = getModule();
  algorithm
    bdae := match bdae
      local
        String name                                     "Name of jacobian";
        BVariable.VariablePointers unknowns             "Variable array of unknowns";
        BEquation.EquationPointers equations            "Equations array";
        BVariable.VariablePointers knowns               "Variable array of knowns"; // is this needed?
        Option<Jacobian> jacobian                       "Resulting jacobian";
        FunctionTree funcTree                           "Function call bodies";
        list<System.System> oldSystems, newSystems = {} "Equation systems before and afterwards";
        Integer idx = 1;

      case BackendDAE.BDAE(varData = BVariable.VAR_DATA_SIM(knowns = knowns), funcTree = funcTree)
        algorithm
          (oldSystems, name) := match systemType
            case NBSystem.SystemType.ODE  then (bdae.ode, "ODEJac");
            case NBSystem.SystemType.INIT then (bdae.init, "INIJac");
            case NBSystem.SystemType.DAE  then (Util.getOption(bdae.dae), "DAEJac");
          end match;

          for syst in oldSystems loop
            (jacobian, funcTree) := match syst
              case System.SYSTEM(unknowns = unknowns, equations = equations)
              /* this needs a unique name! */
              then func(name + intString(idx), unknowns, equations, knowns , funcTree);
            end match;
            syst.jacobian := jacobian;
            newSystems := syst::newSystems;
            idx := idx + 1;
          end for;

        _ := match systemType
          case NBSystem.SystemType.ODE  algorithm bdae.ode  := listReverse(newSystems);       then ();
          case NBSystem.SystemType.INIT algorithm bdae.init := listReverse(newSystems);       then ();
          case NBSystem.SystemType.DAE  algorithm bdae.dae  := SOME(listReverse(newSystems)); then ();
        end match;
        bdae.funcTree := funcTree;
      then bdae;

      else algorithm
        // maybe add failtrace here and allow failing
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + BackendDAE.toString(bdae)});
      then fail();

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
  protected
    Pointer<list<Pointer<Variable>>> seed_vars_ptr = Pointer.create({});
    Pointer<HashTableCrToCr.HashTable> jacobianHT = Pointer.create(HashTableCrToCr.empty());
    Differentiate.DifferentiationArguments diffArguments;

    BEquation.EquationPointers diffedEquations;
    BEquation.EqData eqDataJac;

    list<Pointer<Variable>> all_vars, unknown_vars, aux_vars, alias_vars, depend_vars, res_vars, tmp_vars, seed_vars;
    BVariable.VarData varDataJac;
  algorithm
    // ToDo: apply tearing to split residual/inner variables and equations
    // add inner/tmp cref tuples to HT
    BVariable.VariablePointers.map(unknowns, function makeSeedTraverse(name = name, seed_vars_ptr = seed_vars_ptr, jacobianHT = jacobianHT));

    // Build differentiation argument structure
    diffArguments := Differentiate.DIFFERENTIATION_ARGUMENTS(
      diffCref        = ComponentRef.EMPTY(),             // no explicit cref necessary, rules are set by HT
      jacobianHT      = SOME(Pointer.access(jacobianHT)), // seed and temporary cref hashtable
      diffType        = NBDifferentiate.DifferentiationType.JACOBIAN,
      funcTree        = funcTree,
      diffedFunctions = AvlSetPath.new()
    );

    (diffedEquations, diffArguments) := Differentiate.differentiateEquationPointers(equations, diffArguments);

    // create equation data for jacobian
    // ToDo: split temporary and auxiliares once tearing is applied
    eqDataJac := BEquation.EQ_DATA_JAC(
      equations     = diffedEquations,
      results       = diffedEquations,
      temporary     = BEquation.EquationPointers.empty(),
      auxiliaries   = BEquation.EquationPointers.empty()
    );

    // collect var data
    all_vars      := {};
    unknown_vars  := {};

    seed_vars     := Pointer.access(seed_vars_ptr);
    aux_vars      := seed_vars; // add other auxiliaries later on
    alias_vars    := {};
    depend_vars   := {};

    res_vars      := {};
    tmp_vars      := {}; // ToDo: add this once system has been torn

    varDataJac := BVariable.VAR_DATA_JAC(
      variables     = NBVariable.VariablePointers.fromList(all_vars),
      unknowns      = NBVariable.VariablePointers.fromList(unknown_vars),
      knowns        = knowns,
      auxiliaries   = NBVariable.VariablePointers.fromList(aux_vars),
      aliasVars     = NBVariable.VariablePointers.fromList(alias_vars),
      diffVars      = unknowns,
      dependencies  = NBVariable.VariablePointers.fromList(depend_vars),
      resultVars    = NBVariable.VariablePointers.fromList(res_vars),
      tmpVars       = NBVariable.VariablePointers.fromList(tmp_vars),
      seedVars      = NBVariable.VariablePointers.fromList(seed_vars)
    );

    jacobian := SOME(Jacobian.JAC(varDataJac, eqDataJac));
  end jacobianDefault;

  function makeSeedTraverse
    input output Variable var;
    input String name;
    input Pointer<list<Pointer<Variable>>> seed_vars_ptr;
    input Pointer<HashTableCrToCr.HashTable> jacobianHT;
  protected
    ComponentRef seedCref;
    Pointer<Variable> seedVar;
  algorithm
    (seedCref, seedVar) := BVariable.makeSeedVar(var.name, name);
    // add $SEED_Jac.x variable pointer to the seed variables
    Pointer.update(seed_vars_ptr, seedVar :: Pointer.access(seed_vars_ptr));
    // add x -> $SEED_Jac.x to the hashTable for later lookup
    Pointer.update(jacobianHT, BaseHashTable.add((var.name, seedCref), Pointer.access(jacobianHT)));
  end makeSeedTraverse;

  annotation(__OpenModelica_Interface="backend");
end NBJacobian;
