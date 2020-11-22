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
  import NBCausalize.AdjacencyMatrix;
  import NBCausalize.Matching;
  import StrongComponent = NBStrongComponent;

protected
  // Backend Imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import Jacobian = NBackendDAE.BackendDAE;
  import BVariable = NBVariable;

  // Util imports
  import StringUtil;

public
  uniontype System
    record SYSTEM
      SystemType systemType                           "Type of system: ODE, INIT or DAE";
      BVariable.VariablePointers unknowns             "Variable array of unknowns, subset of full variable array";
      Option<BVariable.VariablePointers> daeUnknowns  "Variable array of unknowns in the case of dae mode";
      BEquation.EquationPointers equations            "Equations array, subset of the full equation array";
      Option<AdjacencyMatrix> adjacencyMatrix         "Adjacency matrix with all additional information";
      Option<Matching> matching                       "Matching (see 2.5)";
      Option<array<StrongComponent>> strongComponents "Strong Components";
      PartitionKind partitionKind                     "Clocked/Continuous partition kind";
      Option<Integer> subPartitionIndex               "For clocked partitions";
      Option<Jacobian> jacobian                       "Analytic jacobian for the integrator";
    end SYSTEM;

    function toString
      input System system;
      output String str;
    algorithm
      str := StringUtil.headline_2(partitionKindString(system.partitionKind) + " " + systemTypeString(system.systemType) + " System") + "\n";
      str := match system.strongComponents
        local
          array<StrongComponent> comps;

        case SOME(comps)
          algorithm
            for i in 1:arrayLength(comps) loop
              str := str + StrongComponent.toString(comps[i], i) + "\n";
            end for;
            if isSome(system.jacobian) then
              str := str + Jacobian.toString(Util.getOption(system.jacobian)) + "\n";
            end if;
        then str;

        else
          algorithm
            str := str +  BVariable.VariablePointers.toString(system.unknowns, "Unknown") + "\n" +
                          BEquation.EquationPointers.toString(system.equations, "Equations") + "\n";
        then str;
      end match;
      // ToDo: add adjacency and matching etc.
    end toString;

    function systemTypeString
      input SystemType systemType;
      output String str;
    algorithm
      str := match systemType
        case SystemType.ODE   then "ODE";
        case SystemType.INIT  then "INIT";
        case SystemType.DAE   then "DAE";
      end match;
    end systemTypeString;

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
      end match;
    end partitionKindString;

  end System;

  // ToDo: Expand with Jacobian and Hessian later on
  type SystemType = enumeration(ODE, DAE, INIT);
  type PartitionKind = enumeration(UNKNOWN, UNSPECIFIED, CLOCKED, CONTINUOUS);


  annotation(__OpenModelica_Interface="backend");
end NBSystem;
