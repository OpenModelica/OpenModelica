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
encapsulated package NBSystem
"file:        NBSystem.mo
 package:     NBSystem
 description: This file contains the data-types used to process individual
              systems of equations.
"

public
  import Adjacency = NBAdjacency;
  import Matching = NBMatching;
  import StrongComponent = NBStrongComponent;

protected
  // NF imports
  import Variable = NFVariable;

  // Backend Imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import BJacobian = NBJacobian;
  import NBEquation.EquationPointers;
  import Jacobian = NBackendDAE.BackendDAE;
  import BVariable = NBVariable;
  import NBVariable.VariablePointers;

  // Util imports
  import DoubleEnded;
  import StringUtil;

public
  // ToDo: Expand with Jacobian and Hessian later on
  type SystemType = enumeration(ODE, ALG, ODE_EVT, ALG_EVT, INI, DAE, JAC);
  type PartitionKind = enumeration(UNKNOWN, UNSPECIFIED, CLOCKED, CONTINUOUS);

  uniontype System
    record SYSTEM
      SystemType systemType                           "Type of system";
      VariablePointers unknowns                       "Variable array of unknowns, subset of full variable array";
      Option<VariablePointers> daeUnknowns            "Variable array of unknowns in the case of dae mode";
      EquationPointers equations                      "Equations array, subset of the full equation array";
      Option<Adjacency.Matrix> adjacencyMatrix        "Adjacency matrix with all additional information";
      Option<Matching> matching                       "Matching (see 2.5)";
      Option<array<StrongComponent>> strongComponents "Strong Components";
      PartitionKind partitionKind                     "Clocked/Continuous partition kind";
      Integer partitionIndex                          "For clocked partitions";
      Option<Jacobian> jacobian                       "Analytic jacobian for the integrator";
    end SYSTEM;

    function toString
      input System system;
      input Integer level = 0;
      output String str;
    algorithm
      str := StringUtil.headline_2(partitionKindString(system.partitionKind) + " " + intString(system.partitionIndex) + " " + systemTypeString(system.systemType) + " System") + "\n";
      str := match system.strongComponents
        local
          array<StrongComponent> comps;

        case SOME(comps)
          algorithm
            for i in 1:arrayLength(comps) loop
              str := str + StrongComponent.toString(comps[i], i) + "\n";
            end for;
        then str;

        else
          algorithm
            str := str +  VariablePointers.toString(system.unknowns, "Unknown") + "\n" +
                          EquationPointers.toString(system.equations, "Equations") + "\n";
        then str;
      end match;

      if level == 1 or level == 3 then
        if isSome(system.adjacencyMatrix) then
          str := str + Adjacency.Matrix.toString(Util.getOption(system.adjacencyMatrix)) + "\n";
        end if;

        if isSome(system.matching) then
          str := str + Matching.toString(Util.getOption(system.matching)) + "\n";
        end if;
      end if;

      if level == 2 then
        if isSome(system.jacobian) then
          str := str + BJacobian.toString(Util.getOption(system.jacobian)) + "\n";
        else
          str := str + StringUtil.headline_2("NO JACOBIAN") + "\n";
        end if;
      end if;
    end toString;

    function toStringList
      input list<System> systems;
      input String header = "";
      output String str = "";
    algorithm
      if not listEmpty(systems) then
        if header <> "" then
          str := StringUtil.headline_1(header) + "\n";
        end if;
        for syst in systems loop
          str := str + System.toString(syst);
        end for;
      end if;
    end toStringList;

    function sort
      input output System system;
    algorithm
      system.unknowns := VariablePointers.sort(system.unknowns);
      system.equations := EquationPointers.sort(system.equations);
    end sort;

    function isEmpty
      "returns true if the system is empty.
      maybe check more than only equations?"
      input System system;
      output Boolean b = EquationPointers.size(system.equations) == 0;
    end isEmpty;

    function isAlgebraic
      input System syst;
      output Boolean b = true;
    algorithm
      for var in VariablePointers.toList(syst.unknowns) loop
          if BVariable.isStateDerivative(var) then
            b := false;
            break;
          end if;
      end for;
    end isAlgebraic;

    function isAlgebraicContinuous
      input System syst;
      output Boolean alg = true;
      output Boolean con = true;
    algorithm
      for var in VariablePointers.toList(syst.unknowns) loop
          if BVariable.isStateDerivative(var) then
            alg := false;
            break;
          end if;
          if BVariable.isDiscrete(var) then
            con := false;
          end if;
          // stop searching if both
          if not (alg or con) then
            break;
          end if;
      end for;
    end isAlgebraicContinuous;

    function categorize
      input System system;
      input DoubleEnded.MutableList<System> ode;
      input DoubleEnded.MutableList<System> alg;
      input DoubleEnded.MutableList<System> ode_evt;
      input DoubleEnded.MutableList<System> alg_evt;
    protected
      Boolean algebraic, continuous;
      System cont_syst, disc_syst;
    algorithm
      (algebraic, continuous) := isAlgebraicContinuous(system);
      _ := match (algebraic, continuous)
        case (true, true) algorithm
          // algebraic continuous
          system.systemType := SystemType.ALG;
          DoubleEnded.push_back(alg, system);
        then ();

        case (false, true) algorithm
          // differential continuous
          system.systemType := SystemType.ODE;
          DoubleEnded.push_back(ode, system);
        then ();

        case (true, false) algorithm
          // algebraic discrete
          system.systemType := SystemType.ALG_EVT;
          DoubleEnded.push_back(alg_evt, system);
        then ();

        case (false, false) algorithm
          // differential discrete
          system.systemType := SystemType.ODE_EVT;
          DoubleEnded.push_back(ode_evt, system);
        then ();

        else fail();
      end match;
    end categorize;

    function getLoopResiduals
      input System syst;
      output list<Pointer<Variable>> residuals = {};
    algorithm
      if Util.isSome(syst.strongComponents) then
        for comp in Util.getOption(syst.strongComponents) loop
          residuals := listAppend(StrongComponent.getLoopResiduals(comp), residuals);
        end for;
      end if;
    end getLoopResiduals;

    function systemTypeString
      input SystemType systemType;
      output String str = "";
    algorithm
      str := match systemType
        case SystemType.ODE         then "ODE";
        case SystemType.ALG         then "ALG";
        case SystemType.ODE_EVT     then "ODE_EVT";
        case SystemType.ALG_EVT     then "ALG_EVT";
        case SystemType.INI         then "INI";
        case SystemType.DAE         then "DAE";
        case SystemType.JAC         then "JAC";
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Unknown system type in match."});
        then fail();
      end match;
    end systemTypeString;

    function systemTypeInteger
      input SystemType systemType;
      output Integer i;
    algorithm
      i := match systemType
        case SystemType.ODE         then 0;
        case SystemType.ALG         then 1;
        case SystemType.ODE_EVT     then 2;
        case SystemType.ALG_EVT     then 3;
        case SystemType.INI         then 4;
        case SystemType.DAE         then 5;
        case SystemType.JAC         then 6;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Unknown system type in match."});
        then fail();
      end match;
    end systemTypeInteger;

  protected
    function partitionKindString
      input PartitionKind partitionKind;
      output String str;
    algorithm
      str := match partitionKind
        case PartitionKind.UNKNOWN      then "UNKNOWN";
        case PartitionKind.UNSPECIFIED  then "UNSPECIFIED";
        case PartitionKind.CLOCKED      then "CLOCKED";
        case PartitionKind.CONTINUOUS   then "CONTINUOUS";
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Unknown partition kind in match."});
          then fail();
      end match;
    end partitionKindString;

  end System;

  annotation(__OpenModelica_Interface="backend");
end NBSystem;
