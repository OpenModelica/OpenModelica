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
encapsulated package NBModule
" file:         NBModule.mo
  package:      NBModule
  description:  This file contains all functions and structures regarding
                generic backend modules and interfaces.

  This file contains following module wrappers:

  *** PRE (Mandatory)
   - eventsInterface
   - detectStatesInterface
   - detectContinuousStatesInterface
   - detectDiscreteStatesInterface

  *** PRE (Optional)
   - aliasInterface

  *** MAIN
   - partitioningInterface
   - causalizeInterface
   - daeModeInterface

  *** POST (Mandatory)
   - jacobianInterface

  *** POST (Optional)
   - tearingInterface
"
public
  import BackendDAE = NBackendDAE;

protected
  // OF imports
  import DAE;

  // NF imports
  import NFFlatten.FunctionTree;

  // Backend imports
  import Adjacency = NBAdjacency;
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationPointers, EqData};
  import Jacobian = NBackendDAE;
  import NBJacobian.JacobianType;
  import StrongComponent = NBStrongComponent;
  import Partition = NBPartition;
  import NBPartitioning.ClockedInfo;
  import BVariable = NBVariable;
  import NBVariable.{VariablePointers, VarData};
  import NBEvents.EventInfo;
  import Inline = NBInline;

  // Util imports
  import System;
  import StringUtil;

public
  partial function wrapper
    input output BackendDAE bdae;
  end wrapper;

  function moduleClockString
    input tuple<String, Real> name_clock;
    output String str;
  protected
    String name;
    Real clck;
  algorithm
    (name, clck) := name_clock;
    str := "\t" + name + StringUtil.repeat(".", 50 - stringLength(name)) + System.sprintff("%.4g", clck);
  end moduleClockString;

// =========================================================================
//                                MAIN MODULES
// =========================================================================

//                               PARTITIONING
// *************************************************************************
  partial function partitioningInterface
    "Partitioning
     This function is only allowed to create partitions of specialized Kind
     by creating an adjacency matrix using provided variables and equations."
    input Partition.Kind kind;
    input VariablePointers variables;
    input EquationPointers equations;
    input VariablePointers clocks;
    input EquationPointers clocked;
    input ClockedInfo info;
    output list<Partition.Partition> partitions;
  end partitioningInterface;

//                               CAUSALIZE
// *************************************************************************
  partial function causalizeInterface
    "Causalize
     This function is allowed to add variables, equations and manipulate the
     function tree (index reduction)."
    input output Partition.Partition partition;
    input output VarData varData;
    input output EqData eqData;
    input output FunctionTree funcTree;
  end causalizeInterface;

//                           RESOLVING SINGULARITIES
//                  Index Reduction + Balance Initialization
// *************************************************************************
  partial function resolveSingularitiesInterface
    input output Adjacency.Matrix adj;
    input output Adjacency.Matrix full;
    input output VariablePointers variables;
    input output EquationPointers equations;
    input output VarData varData;
    input output EqData eqData;
    input output FunctionTree funcTree;
    input Matching matching;
    input Option<Adjacency.Mapping> mapping_opt;
    output Boolean changed;
  end resolveSingularitiesInterface;

//                               DAEMODE
// *************************************************************************
  partial function daeModeInterface
    "DAEMode
     This function is only allowed to create a list of new partitions for dae Mode."
    input output list<Partition.Partition> partitions;
  end daeModeInterface;

// =========================================================================
//                         MANDATORY PRE-OPT MODULES
// =========================================================================

//                            COLLECT EVENTS
// *************************************************************************
  partial function eventsInterface
    "Events
     This function is only allowed to read and change equations and create new
     discrete zero crossing equations and variables. ($TEV, $SEV)
     It also fills the EventInfo object."
    input output VarData varData          "Data containing variable pointers";
    input output EqData eqData            "Data containing equation pointers";
    input output EventInfo eventInfo      "object containing all zero crossings";
    input FunctionTree funcTree           "function tree for differentiation (solve)";
  end eventsInterface;

//                               DETECT STATES
// *************************************************************************
  partial function detectStatesInterface
    "DetectStates
     This function is only allowed to read and change equations, change algebraic
     variables to states and create state derivatives. It also detects der() and
     pre() calls and replaces them with $DER and $PRE.
     Sub-Modules:
      - DetectContinuousStates
      - DetectDiscreteStates"
    input output VarData varData                "Data containing variable pointers";
    input output EqData eqData                  "Data containing equation pointers";
    input detectContinuousStatesInterface continuousFunc  "Subroutine for continuous states";
    input detectDiscreteStatesInterface discreteFunc      "Subroutine for discrete states";
  end detectStatesInterface;

  partial function detectContinuousStatesInterface
    "DetectContinuousStates
     This function is only allowed to read and change equations, change algebraic
     variables to states and create state derivatives."
    input output VariablePointers variables     "All variables";
    input output VariablePointers unknowns      "Unknowns";
    input output VariablePointers knowns        "Knowns";
    input output VariablePointers initials      "Initial unknowns";
    input output VariablePointers states        "States";
    input output VariablePointers derivatives   "State derivatives (der(x) -> $DER.x)";
    input output VariablePointers algebraics    "Algebraic variables";
    input EquationPointers equations            "Partition equations";
    output list<Pointer<Equation>> aux_eqns     "New auxiliary equations";
  end detectContinuousStatesInterface;

  partial function detectDiscreteStatesInterface
    "DetectDiscreteStates
     This function is only allowed to read and change equations, change algebraic
     variables to discrete and create previous discrete variables."
    input output VariablePointers variables       "All variables";
    input output EquationPointers equations       "ONLY discrete or initial equations!";
    input output VariablePointers knowns          "Knowns";
    input output VariablePointers initials        "Initial unknowns";
    input output VariablePointers discretes       "Discrete variables";
    input output VariablePointers discrete_states "Discrete State variables";
    input output VariablePointers clocked_states  "Clocked State variables";
    input output VariablePointers previous        "Previous discrete variables (pre(d) -> $PRE.d)";
    input String context                          "only for debugging";
  end detectDiscreteStatesInterface;

// =========================================================================
//                         Optional PRE-OPT MODULES
// =========================================================================

//                                 ALIAS
// *************************************************************************
  partial function functionAliasInterface
    "Alias
     This module is allowed to read and remove equations and move variables from
     unknowns to knowns. Since this can also affect all other pointer arrays, the
     full variable data is needed. All things that are allowed to be changed
     are pointers, so no return value."
    input output VarData varData         "Data containing variable pointers";
    input output EqData eqData           "Data containing equation pointers";
  end functionAliasInterface;


  partial function aliasInterface
    "Alias
     This module is allowed to read and remove equations and move variables from
     unknowns to knowns. Since this can also affect all other pointer arrays, the
     full variable data is needed. All things that are allowed to be changed
     are pointers, so no return value."
    input output VarData varData         "Data containing variable pointers";
    input output EqData eqData           "Data containing equation pointers";
  end aliasInterface;

//                                 INLINE
// *************************************************************************
  partial function inlineInterface
    "Inline
     This module is allowed to read, change and add equations. It uses the
     function tree to evaluate and inline functions."
    input output EqData eqData                "Data containing equation pointers";
    input output VarData varData              "Data containing variable pointers, for lowering purposes";
    input FunctionTree funcTree               "function tree for differentiation (solve)";
    input list<DAE.InlineType> inline_types   "Inline types for which to inline at the current state";
  end inlineInterface;

// =========================================================================
//                         MANDATORY POST-OPT MODULES
// =========================================================================

//                               JACOBIAN
// *************************************************************************
  partial function jacobianInterface
    "The jacobian is only allowed to read the variables and equations of current
    partition and additionally the global known variables. It needs a unique name
    and is allowed to manipulate the function tree.
    [!] This function can not only be used as an optimization module but also for
    nonlinear partitions, state sets, linearization and dynamic optimization."
    input String name                                     "Name of jacobian";
    input JacobianType jacType                            "Type of jacobian (sim/nonlin)";
    input VariablePointers seedCandidates                 "differentiate by these";
    input VariablePointers partialCandidates              "solve the equations for these";
    input EquationPointers equations                      "Equations array";
    input VariablePointers knowns                         "Variable array of knowns";
    input Option<array<StrongComponent>> strongComponents "Strong Components";
    output Option<Jacobian> jacobian                      "Resulting jacobian";
    input output FunctionTree funcTree                    "Function call bodies";
    input Boolean init;
  end jacobianInterface;

// =========================================================================
//                         Optional POST-OPT MODULES
// =========================================================================

//                                 TEARING
// *************************************************************************
  partial function tearingInterface
    "Tearing
     The tearing module analyzes each strong component and applies tearing if
     necessary. Only has access to the strong component itself, everything else
     accessable with pointers."
    input output StrongComponent comp     "the suspected algebraic loop.";
    input output Adjacency.Matrix full    "the full adjacency matrix containing solvability info";
    input output FunctionTree funcTree    "Function call bodies";
    input output Integer index            "current unique loop index";
    input VariablePointers variables      "all variables";
    input EquationPointers equations      "all equations";
    input Pointer<Integer> eq_index       "equation index";
    input Partition.Kind kind = NBPartition.Kind.ODE   "partition type";
  end tearingInterface;

  annotation(__OpenModelica_Interface="backend");
end NBModule;
