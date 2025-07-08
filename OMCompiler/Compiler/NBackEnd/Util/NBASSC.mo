/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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
encapsulated package NBASSC
"file:        NBASSC.mo
 package:     NBASSC
 description: This file contains the functions which will perform analytical to structural singularity conversion.
"

protected
  import NBEquation.EquationPointers;
  import NBVariable.VariablePointers;

public
  function main
    input EquationPointers eqns;
    input VariablePointers vars;
  protected
    array<list<Integer>> indices, values;
  algorithm
    // ### pseudo code of what shall happen
    // for eqn in eqns:
    //   b = true
    //   crefs = find all crefs of vars in eqn
    //   for cref in crefs
    //      diff = differentiate eqn for cref
    //      simplify diff
    //      if diff is integer
    //          save (eqn, cref) -> diff to map (diffs)
    //      else
    //          eqn is not part of linear system (b=false)
    //          break
    //      end if
    //    end for
    //    if b then
    //      save eqn to set (int_eqns)
    //      save crefs to set (int_crefs)
    //      save eqn -> crefs in map (rows)
    //    end if
    //  end for
    //
    //  enumerate sets int_eqns and int_crefs
    //  initialize indices[] and values[] of size |int_eqns|
    //
    //  for eqn in int_eqns
    //    for cref in rows(eqn)
    //      eqn_index = get index of equation eqn in int_eqns
    //      var_index = get index of variable cref in int_crefs
    //      indices[eqn_index] += append var_index
    //      values[eqn_index] += append diffs(eqn,cref)
    //    end for
    //  end for

    // remove this dummy section
    // ################################
    indices := arrayCreate(3, {});
    values := arrayCreate(3, {});
    indices[1] := {1,2};
    values[1] := {10,2};
    indices[2] := {1};
    values[2] := {5};
    indices[3] := {1,3};
    values[3] := {8,-2};
    // ################################


    setMatrix(3,3,5,indices,values);
    //printMatrix();
    freeMatrix();
  end main;

  function setMatrix
    input Integer nv                "number of variables";
    input Integer ne                "number of equations";
    input Integer nz                "number of nonzero values";
    input array<list<Integer>> adj  "adjacency matrix";
    input array<list<Integer>> val  "value matrix";
    external "C" ASSC_setMatrix(nv,ne,nz,adj,val) annotation(Library = "omcruntime");
  end setMatrix;

  function freeMatrix
    external "C" ASSC_freeMatrix() annotation(Library = "omcruntime");
  end freeMatrix;

  function printMatrix
    external "C" ASSC_printMatrix() annotation(Library = "omcruntime");
  end printMatrix;

  annotation(__OpenModelica_Interface="backend");
end NBASSC;