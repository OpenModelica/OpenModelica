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
encapsulated package NBCausalize
"file:        NBCausalize.mo
 package:     NBCausalize
 description: This file contains the functions which perform the causalization process;
"

public
  import Module = NBModule;

protected
  // NF imports
  import ComponentRef = NFComponentRef;
  import NFFlatten.FunctionTree;
  import Variable = NFVariable;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import Differentiate = NBDifferentiate;
  import NBEquation.EqData;
  import NBEquation.Equation;
  import NBEquation.EquationAttributes;
  import NBEquation.EquationPointers;
  import StrongComponent = NBStrongComponent;
  import System = NBSystem;
  import BVariable = NBVariable;
  import NBVariable.VarData;
  import NBVariable.VariablePointers;

  // util imports
  import Error;
  import GC;
  import HashTableCrToInt = NBHashTableCrToInt;
  import List;
  import BackendUtil = NBBackendUtil;
  import StringUtil;

public
  function main extends Module.wrapper;
    input System.SystemType systemType;
  algorithm
    bdae := match (systemType, bdae)
      local
        System.System new_system;
        list<System.System> systems, new_systems = {};
        VarData varData;
        EqData eqData;
        FunctionTree funcTree;

      case (System.SystemType.ODE, BackendDAE.MAIN(ode = systems, varData = varData, eqData = eqData, funcTree = funcTree))
        algorithm
          for system in systems loop
            (new_system, varData, eqData, funcTree) := causalizeScalar(system, varData, eqData, funcTree);
            new_systems := new_system :: new_systems;
          end for;
          bdae.ode := listReverse(new_systems);
          bdae.varData := varData;
          bdae.eqData := eqData;
      then bdae;

      case (System.SystemType.INIT, BackendDAE.MAIN(init = systems, varData = varData, eqData = eqData, funcTree = funcTree))
        algorithm
          for system in systems loop
            (new_system, varData, eqData, funcTree) := causalizeScalar(system, varData, eqData, funcTree);
            new_systems := new_system :: new_systems;
          end for;
          bdae.init := listReverse(new_systems);
          bdae.varData := varData;
          bdae.eqData := eqData;
      then bdae;

      case (System.SystemType.DAE, BackendDAE.MAIN(dae = SOME(systems), varData = varData, eqData = eqData, funcTree = funcTree))
        algorithm
          for system in systems loop
            (new_system, varData, eqData, funcTree) := causalizeDAEMode(system, varData, eqData, funcTree);
            new_systems := new_system :: new_systems;
          end for;
          bdae.dae := SOME(listReverse(new_systems));
          bdae.varData := varData;
          bdae.eqData := eqData;
      then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed with system type " + System.System.systemTypeString(systemType) + "!"});
      then fail();
    end match;
  end main;

  function simple
    input VariablePointers vars;
    input BEquation.EquationPointers eqs;
    output list<StrongComponent> comps;
  protected
    AdjacencyMatrix adj;
    Matching matching;
  algorithm
     // create scalar adjacency matrix for now
    adj := AdjacencyMatrix.create(vars, eqs, AdjacencyMatrixType.SCALAR);
    matching := Matching.regular(adj);
    comps := Sorting.tarjan(adj, matching, vars, eqs);
  end simple;

protected
  function causalizeScalar extends Module.causalizeInterface;
  protected
    VariablePointers variables;
    EquationPointers equations;
    AdjacencyMatrix adj;
    Matching matching;
    list<StrongComponent> comps;
  algorithm
    // compress the arrays to remove gaps
    variables := VariablePointers.compress(system.unknowns);
    equations := EquationPointers.compress(system.equations);

    // create scalar adjacency matrix for now
    adj := AdjacencyMatrix.create(variables, equations, AdjacencyMatrixType.SCALAR);
    (matching, adj, variables, equations, funcTree, varData, eqData) := Matching.singular(adj, variables, equations, funcTree, varData, eqData, false, true);
    comps := Sorting.tarjan(adj, matching, variables, equations);

    system.unknowns := variables;
    system.equations := equations;
    system.adjacencyMatrix := SOME(adj);
    system.matching := SOME(matching);
    system.strongComponents := SOME(listArray(comps));
  end causalizeScalar;

  function causalizeDAEMode extends Module.causalizeInterface;
  protected
    Pointer<list<StrongComponent>> acc = Pointer.create({});
  algorithm
    // create all components as residuals for now
    // ToDo: use tearing to get inner/tmp equations
    EquationPointers.mapPtr(system.equations, function StrongComponent.makeDAEModeResidualTraverse(acc = acc));
    system.strongComponents := SOME(List.listArrayReverse(Pointer.access(acc)));
  end causalizeDAEMode;

public
  type AdjacencyMatrixType        = enumeration(SCALAR, ARRAY);
  type AdjacencyMatrixStrictness  = enumeration(FULL, LINEAR, STATE_SELECT);

  uniontype AdjacencyMatrix
    record ARRAY_ADJACENCY_MATRIX
      AdjacencyMatrixQuarter m;
      AdjacencyMatrixQuarterT mT;
      AdjacencyMatrixStrictness st;
      /* Maybe add optional markings here */
    end ARRAY_ADJACENCY_MATRIX;

    record SCALAR_ADJACENCY_MATRIX
      array<list<Integer>> m;
      array<list<Integer>> mT;
      AdjacencyMatrixStrictness st;
    end SCALAR_ADJACENCY_MATRIX;

    record EMPTY_ADJACENCY_MATRIX
    end EMPTY_ADJACENCY_MATRIX;

    function create
      input VariablePointers vars;
      input EquationPointers eqs;
      input AdjacencyMatrixType ty;
      input AdjacencyMatrixStrictness st = AdjacencyMatrixStrictness.FULL;
      output AdjacencyMatrix adj;
    algorithm
      adj := match ty
        case AdjacencyMatrixType.SCALAR then createScalar(vars, eqs, st);
        case AdjacencyMatrixType.ARRAY algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array adjacency matrices are not supported yet."});
        then fail();
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown adjacency matrix type."});
        then fail();
      end match;
    end create;

    function toString
      input AdjacencyMatrix adj;
      input output String str = "";
    algorithm
      str := StringUtil.headline_2(str + "AdjacencyMatrix") + "\n";
      str := match adj
        case ARRAY_ADJACENCY_MATRIX() then str + "\n ARRAY NOT YET SUPPORTED \n";
        case SCALAR_ADJACENCY_MATRIX() algorithm
          if arrayLength(adj.m) > 0 then
            str := str + StringUtil.headline_4("Normal Adjacency Matrix (row = equation)");
            str := str + toStringSingle(adj.m);
          end if;
          str := str + "\n";
          if arrayLength(adj.mT) > 0 then
            str := str + StringUtil.headline_4("Transposed Adjacency Matrix (row = variable)");
            str := str + toStringSingle(adj.mT);
          end if;
          str := str + "\n";
        then str;
        case EMPTY_ADJACENCY_MATRIX() then str + StringUtil.headline_4("Empty Adjacency Matrix") + "\n";
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown adjacency matrix type."});
        then fail();
      end match;
    end toString;

  protected
    function toStringSingle
      input array<list<Integer>> m;
      output String str = "";
    algorithm
      for row in 1:arrayLength(m) loop
        str := str + "\t(" + intString(row) + ")\t" + List.toString(m[row], intString) + "\n";
      end for;
    end toStringSingle;

    function createScalar
      input VariablePointers vars;
      input EquationPointers eqs;
      input AdjacencyMatrixStrictness st = AdjacencyMatrixStrictness.FULL;
      output AdjacencyMatrix adj;
    protected
      Equation eqn;
      list<ComponentRef> dependencies, nonlinear_dependencies;
      Pointer<Equation> derivative;
      list<Pointer<BEquation.Equation>> eqn_lst;
      array<list<Integer>> m, mT;
      Integer eqn_idx = 1;
    algorithm
      if ExpandableArray.getNumberOfElements(eqs.eqArr) > 0 then
        eqn_lst := EquationPointers.toList(eqs);
        // create empty adjacency matrix and traverse equations to fill it
        m := arrayCreate(listLength(eqn_lst), {});
        for eqn_ptr in eqn_lst loop
          eqn := Pointer.access(eqn_ptr);
          dependencies := BEquation.Equation.collectCrefs(eqn, function getDependentCref(ht = vars.ht));
          // if we only want linear dependencies, try to look if there is a derivative saved. remove all dependencies
          // of that equation because those are the nonlinear ones.
          // for now fail if there is no derivative, possible fallback: differentiate eq and save it
          _ := match Equation.getAttributes(eqn)
            case EquationAttributes.EQUATION_ATTRIBUTES(derivative = SOME(derivative))
              guard(st > AdjacencyMatrixStrictness.FULL)
              algorithm
                nonlinear_dependencies := BEquation.Equation.collectCrefs(Pointer.access(derivative), function getDependentCref(ht = vars.ht));
                dependencies := List.setDifferenceOnTrue(dependencies, nonlinear_dependencies, ComponentRef.isEqual);
                if st == AdjacencyMatrixStrictness.STATE_SELECT then
                  // if we are preparing for state selection we only search for linear occurences. One exception
                  // are StateSelect.NEVER variables, which are allowed to appear nonlinear. but they have to be
                  // the last checked option, so they have a negative index and are afterwards sorted to be at the end
                  // of the list.
                  (nonlinear_dependencies, _) := List.extractOnTrue(nonlinear_dependencies, function BVariable.checkCref(func = function BVariable.isStateSelect(stateSelect = NFBackendExtension.StateSelect.NEVER)));
                  m[eqn_idx] := getDependentCrefIndices(nonlinear_dependencies, vars.ht, true);
                end if;
            then ();
            case EquationAttributes.EQUATION_ATTRIBUTES(derivative = NONE())
              guard(st > AdjacencyMatrixStrictness.FULL)
              algorithm
                Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because no derivative is saved and linear adjacency matrix is required!"});
            then fail();
            else ();
          end match;
          m[eqn_idx] := listAppend(getDependentCrefIndices(dependencies, vars.ht), m[eqn_idx]);
          eqn_idx := eqn_idx + 1;
        end for;
        mT := transposeScalar(m, ExpandableArray.getLastUsedIndex(vars.varArr));

        // after proper sorting fixup the indices
        if st == AdjacencyMatrixStrictness.STATE_SELECT then
          m := absoluteMatrix(m);
          mT := absoluteMatrix(mT);
        end if;

        adj := SCALAR_ADJACENCY_MATRIX(m, mT, st);
      else
        adj := EMPTY_ADJACENCY_MATRIX();
      end if;
    end createScalar;

    function transposeScalar
      input array<list<Integer>> m      "original matrix";
      input Integer size                "size of the transposed matrix (does not have to be square!)";
      output array<list<Integer>> mT    "transposed matrix";
    algorithm
      mT := arrayCreate(size, {});
      // loop over all elements and store them in reverse
      for row in 1:arrayLength(m) loop
        for idx in m[row] loop
          try
            if idx > 0 then
              mT[idx] := row :: mT[idx];
            else
              mT[intAbs(idx)] := -row :: mT[intAbs(idx)];
            end if;
          else
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for variable index " + intString(idx) + ".
              The variables have to be dense (without empty spaces) for this to work!"});
          end try;
        end for;
      end for;
      // sort the transposed matrix
      // bigger to lower such that negative entries are at the and
      for row in 1:arrayLength(mT) loop
        mT[row] := List.sort(mT[row], intLt);
      end for;
    end transposeScalar;

    function absoluteMatrix
      input output array<list<Integer>> m;
    algorithm
      for row in 1:arrayLength(m) loop
        m[row] := list(intAbs(i) for i in m[row]);
      end for;
    end absoluteMatrix;

    function getDependentCref
      input output ComponentRef cref          "the cref to check";
      input Pointer<list<ComponentRef>> acc   "accumulator for relevant crefs";
      input HashTableCrToInt.HashTable ht     "hash table to check for relevance";
    algorithm
      if BaseHashTable.hasKey(cref, ht) then
        Pointer.update(acc, cref :: Pointer.access(acc));
      end if;
    end getDependentCref;

    function getDependentCrefIndices
      input list<ComponentRef> dependencies   "dependent var crefs";
      input HashTableCrToInt.HashTable ht     "hash table to check for relevance";
      input Boolean negate = false;
      output list<Integer> indices = {};
    algorithm
      if negate then
        for cref in dependencies loop
          indices := -BaseHashTable.get(cref, ht) :: indices;
        end for;
      else
        for cref in dependencies loop
          indices := BaseHashTable.get(cref, ht) :: indices;
        end for;
      end if;
      // remove duplicates and sort
      indices := List.sort(List.unique(indices), intLt);
    end getDependentCrefIndices;
  end AdjacencyMatrix;

  /*
    Regular slice. Always has three elements.
    E.g. Start=1, Stop=91, Step=3
    =>  {1,4,7,...,88,91}
    The order matters for eq <=> var matchings!
    [1,91,3] <> [91,1,-3]
  */
  type RegularSlice = array<Integer>;

  /*
    Vector slice type (one dimension). Contains a list
    of static singleton indices and a list of regular
    slices. Each regular slice needs to represent the
    same number of (scalarized) element for it to be
    consistent. The singletons are assumed to be static
    and occur for every scalarized instance of the
    regular slices. E.g.
    for i in 1:3 loop
      x[i] = x[4];
    end for;
    => ({4}, {[1,3,1]})
  */
  uniontype VectorSlice
    record VECTOR_SLICE
      "Full dimension slice."
      list<Integer> singletons       "List of single unordered indices.";
      list<RegularSlice> regSlices   "List of regular slicings.";
    end VECTOR_SLICE;
  end VectorSlice;

  /*
    Tensors slice (multi dimensional). Contains an array
    of all dimension sizes and an array of vector slices
    for each dimension. Each vector slice cannot contain
    elements exceeding the corresponding dimension size.
  */
  uniontype TensorSlice
    record TENSOR_SLICE
      "Slice through all dimensions."
      array<RegularSlice> itSlice     "Iterator slice.";
      array<VectorSlice> vecSlices    "Single dimension slicings.";
    end TENSOR_SLICE;
  end TensorSlice;

  /*
    General indexed slice. The index refers to the
    variable or equation the slice belongs to.
  */
  uniontype IndexSlice
    record INDEX_SLICE
      Integer index                   "Index of variable or equation";
      TensorSlice tenSlice            "Multi dimensional slicing";
    end INDEX_SLICE;
  end IndexSlice;

  /* Adjacency matrix structure. */
  uniontype AdjacencyRow
    record ADJACENCY_ROW
      array<RegularSlice> itSlice     "Iterator slice.";
      list<IndexSlice> indSlice       "Indexed slice for each appearing variable or equation.";
    end ADJACENCY_ROW;
  end AdjacencyRow;

  type AdjacencyMatrixQuarter = array<AdjacencyRow> "Normal or Transposed.";
  type AdjacencyMatrixQuarterT = AdjacencyMatrixQuarter;


  /* add scalar Adjacency Matrix for simple stuff */


  /* =======================================
                    MATCHING
     ======================================= */

  /* New matching structure for slice matching */
  uniontype SliceAssignment
    record SLICE_ASSIGNMENT
      TensorSlice tenSlice         "Assigned tensor slice of current row";
      IndexSlice indSlice          "Assigned tensor slice of indexed column";
    end SLICE_ASSIGNMENT;
  end SliceAssignment;

  uniontype Matching
    record ARRAY_MATCHING
       array<list<SliceAssignment>> varToEq;
       array<list<SliceAssignment>> eqToVar;
    end ARRAY_MATCHING;

    record SCALAR_MATCHING
      array<Integer> var_to_eqn;
      array<Integer> eqn_to_var;
    end SCALAR_MATCHING;

    record EMPTY_MATCHING
    end EMPTY_MATCHING;

    function toString
      input Matching matching;
      input output String str = "";
    algorithm
      str := match matching
        case SCALAR_MATCHING() algorithm
          str := StringUtil.headline_2(str + "Scalar Matching") + "\n";
          str := str + toStringSingle(matching.var_to_eqn, false) + "\n";
          str := str + toStringSingle(matching.eqn_to_var, true) + "\n";
        then str;
        case ARRAY_MATCHING() algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array matching is not yet supported."});
        then fail();
        case EMPTY_MATCHING() then str + StringUtil.headline_2(str + "Empty Matching") + "\n";
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
        then fail();
      end match;
    end toString;

    function regular
      "author: kabdelhak
      Regular matching algorithm for bipartite graphs by Constantinos C. Pantelides.
      First published in doi:10.1137/0909014"
      input AdjacencyMatrix adj;
      input Boolean transposed = false        "transpose matching if true";
      input Boolean partially = false         "do not fail on singular systems and return partial matching if true";
      output Matching matching;
    algorithm
       matching := match adj
        case SCALAR_ADJACENCY_MATRIX() algorithm
          // marked equations irrelevant for regular matching
          if transposed then
            (matching, _) := scalarMatching(adj.mT, adj.m, transposed, partially);
          else
            (matching, _) := scalarMatching(adj.m, adj.mT, transposed, partially);
          end if;
        then matching;
        case ARRAY_ADJACENCY_MATRIX() algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array matching is not yet supported."});
        then fail();
        case EMPTY_ADJACENCY_MATRIX() then EMPTY_MATCHING();
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
        then fail();
      end match;
    end regular;

    function singular
      "author: kabdelhak
      Matching algorithm for bipartite graphs by Constantinos C. Pantelides.
      First published in doi:10.1137/0909014
      In the case of singular systems in tries to resolve it by applying index reduction
      using the dummy derivative method by Sven E. Mattsson and Gustaf Söderlind
      First published in doi:10.1137/0914043

      algorithm:
        - apply pantelides but carry list of singular markings (eqs)
        - whenever singular - add all current marks to singular markings
        - if done and list is not empty -> index reduction
      "
      output Matching matching;
      input AdjacencyMatrix adj;
      output AdjacencyMatrix new_adj = adj;
      input output VariablePointers vars;
      input output EquationPointers eqns;
      input output FunctionTree funcTree;
      input output VarData varData;
      input output EqData eqData;
      input Boolean transposed = false        "transpose matching if true";
      input Boolean partially = false         "do not fail on singular systems and return partial matching if true";
    algorithm
      matching := match adj
        local
          list<list<Integer>> marked_eqns;

        case SCALAR_ADJACENCY_MATRIX()  algorithm
          if transposed then
            (matching, marked_eqns) := scalarMatching(adj.mT, adj.m, transposed, partially);
          else
            (matching, marked_eqns) := scalarMatching(adj.m, adj.mT, transposed, partially);
          end if;

          // some equations could not be matched --> apply index reduction
          if not listEmpty(marked_eqns) then
            (vars, eqns, varData, eqData, funcTree) := IndexReduction.main(vars, eqns, varData, eqData, funcTree, List.flatten(marked_eqns));
            // compute new adjacency matrix (ToDo: keep more of old information)
            new_adj := AdjacencyMatrix.create(vars, eqns, AdjacencyMatrixType.SCALAR);
            // restart matching with new information
            (matching, new_adj, vars, eqns, funcTree, varData, eqData) := Matching.singular(new_adj, vars, eqns, funcTree, varData, eqData, false, true);
          end if;
        then matching;

        case ARRAY_ADJACENCY_MATRIX() algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array matching is not yet supported."});
        then fail();

        case EMPTY_ADJACENCY_MATRIX() then EMPTY_MATCHING();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
        then fail();
      end match;
    end singular;

    function getUnmatched
      input Matching matching;
      input VariablePointers variables;
      input EquationPointers equations;
      output list<Pointer<Variable>> matched_vars = {}, unmatched_vars = {};
      output list<Pointer<Equation>> matched_eqns = {}, unmatched_eqns = {};
    algorithm
      _ := match matching
        case SCALAR_MATCHING() algorithm
          // check if variables are matched and sort them accordingly
          for var in 1:arrayLength(matching.var_to_eqn) loop
            if matching.var_to_eqn[var] > 0 then
              matched_vars := ExpandableArray.get(var, variables.varArr) :: matched_vars;
            else
              unmatched_vars := ExpandableArray.get(var, variables.varArr) :: unmatched_vars;
            end if;
          end for;

          // check if equations are matched and sort them accordingly
          for eqn in 1:arrayLength(matching.eqn_to_var) loop
            if matching.eqn_to_var[eqn] > 0 then
              matched_eqns := ExpandableArray.get(eqn, equations.eqArr) :: matched_eqns;
            else
              unmatched_eqns := ExpandableArray.get(eqn, equations.eqArr) :: unmatched_eqns;
            end if;
          end for;
        then ();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because arrays are not yet supported."});
        then fail();
      end match;
    end getUnmatched;

  protected
    function toStringSingle
      input array<Integer> mapping;
      input Boolean inverse;
      output String str;
    protected
      String head = if inverse then "equation to variable" else "variable to equation";
      String from = if inverse then "eqn" else "var";
      String to   = if inverse then "var" else "eqn";
    algorithm
      str := StringUtil.headline_4(head);
      for i in 1:arrayLength(mapping) loop
        str := str + "\t" + from + " " + intString(i) + " --> " + to + " " + intString(mapping[i]) + "\n";
      end for;
    end toStringSingle;

    function scalarMatching
      input array<list<Integer>> m;
      input array<list<Integer>> mT;
      input Boolean transposed = false        "transpose matching if true";
      input Boolean partially = false         "do not fail on singular systems and return partial matching if true";
      output Matching matching;
      // this needs partially = true to get computed. Otherwise it fails on singular systems
      output list<list<Integer>> marked_eqns = {}   "marked equations for index reduction in the case of a singular system";
    protected
      Integer nVars = arrayLength(mT), nEqns = arrayLength(m);
      array<Integer> var_to_eqn;
      array<Integer> eqn_to_var;
      array<Boolean> var_marks;
      array<Boolean> eqn_marks;
      Boolean pathFound;
    algorithm
      var_to_eqn := arrayCreate(nVars, -1);
      // loop over all equations and try to find an augmenting path
      // to match each uniquely to a variable
      for eqn in 1:nEqns loop
        var_marks := arrayCreate(nVars, false);
        eqn_marks := arrayCreate(nEqns, false);
        (var_to_eqn, var_marks, eqn_marks, pathFound) := augmentPath(eqn, m, mT, var_to_eqn, var_marks, eqn_marks);
        // if it is not possible index reduction needs to be applied
        if not pathFound then
          if not partially then
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the system is structurally singular. Index Reduction is not yet supported"});
          elseif transposed then
            // if transposed the variable marks represent equations
            marked_eqns := BackendUtil.findTrueIndices(var_marks) :: marked_eqns;
          else
            marked_eqns := BackendUtil.findTrueIndices(eqn_marks) :: marked_eqns;
          end if;
        end if;
      end for;

      // create inverse matching
      eqn_to_var := arrayCreate(nEqns, -1);
      for var in 1:nVars loop
        if var_to_eqn[var] > 0 then
          eqn_to_var[var_to_eqn[var]] := var;
        end if;
      end for;

      // free auxiliary arrays
      if nEqns > 0 then
        GC.free(var_marks);
        GC.free(eqn_marks);
      end if;

      // create the matching structure
      matching := if transposed then SCALAR_MATCHING(eqn_to_var, var_to_eqn) else SCALAR_MATCHING(var_to_eqn, eqn_to_var);
    end scalarMatching;

    function augmentPath
      input Integer eqn;
      input array<list<Integer>> m;
      input array<list<Integer>> mT;
      input output array<Integer> var_to_eqn;
      input output array<Boolean> var_marks;
      input output array<Boolean> eqn_marks;
      output Boolean pathFound = false;
    algorithm
      eqn_marks[eqn] := true;
      // loop over each edge and try to find an unmatched variable
      for var in m[eqn] loop
        if var_to_eqn[var] <= 0 then
          pathFound := true;
          var_to_eqn[var] := eqn;
          return;
        end if;
      end for;

      // if no umatched variable can be found, loop over all edges again
      // and try to recursively revoke an old matching decision
      for var in m[eqn] loop
        if not var_marks[var] then
          var_marks[var] := true;
          // recursive call
          (var_to_eqn, var_marks, eqn_marks, pathFound) := augmentPath(var_to_eqn[var], m, mT, var_to_eqn, var_marks, eqn_marks);
          if pathFound then
            var_to_eqn[var] := eqn;
            return;
          end if;
        end if;
      end for;
    end augmentPath;
  end Matching;

  encapsulated package IndexReduction
    public
      import BackendExtension = NFBackendExtension;
      import ComponentRef = NFComponentRef;
      import NFFlatten.FunctionTree;

      import NBCausalize.AdjacencyMatrix;
      import Differentiate = NBDifferentiate;
      import BEquation = NBEquation;
      import NBEquation.EqData;
      import NBEquation.Equation;
      import NBEquation.EquationPointers;
      import NBCausalize.Matching;
      import NBCausalize.Sorting;
      import BVariable = NBVariable;
      import NBVariable.VarData;
      import NBVariable.Variable;
      import NBVariable.VariablePointers;

      import BackendUtil = NBBackendUtil;

    function main
      "algorithm
          1. IR
          - get unkowns and eqs from markings and arrays
          - collect state candidates from constraint eqs
          - differentiate all eqs and collect new derivatives

          2. DUMMY DERIVATIVE
          - sort vars with priority (StateSelect)
          - (ToDo: remove always vars)
          - create adjacency matrix from original vars/eqs
          - match the system with inverse matching to respect ordering
          - do not kick out never variables (provided by ordering)
          - (ToDo: fail if a never variable could not be chosen)
          - see if any equations are unmatched
            - none unmatched -> static state selection
            - any unmatched -> dynamic state selection with remaining eqs and vars

          3. STATIC AND DYNAMIC
          - make all matched variables DUMMY_STATES and all corresponding derivatives DUMMY_DERIVATIVES
          - move DUMMY_STATES to algebraic vars

          4. STATIC
          - no additional tasks

          (ToDo: 5. DYNAMIC)
          - make ALL variables (besides StateSelect = always) DUMMY_STATES and corresponding derivatives DUMMY_DERIVATIVES
          - create state set from remaining eqs and vars
          - create a state and derivative variable for each remaining eq ($SET.x, $SET.dx)
          - create state selection matrix $SET.A (parameter)
          - create equations $SET.x[i] = sum($SET.A[i,j]*DUMMY_STATE[j] | forall j)
          - create equations $SET.dx[i] = sum($SET.A[i,j]*DUMMY_DERIVATIVE[j] | forall j)

          6. AFTER IR
          - add differentiated equations
          - add adjacency matrix entries
          - add new variables in correct arrays
        "
      input output VariablePointers variables;
      input output EquationPointers equations;
      input output VarData varData;
      input output EqData eqData;
      input output FunctionTree funcTree;
      input list<Integer> marked_eqns;
    protected
      Pointer<Equation> constraint, diffed_eqn;
      list<ComponentRef> candidates;
      list<Pointer<Variable>> state_candidates = {}, states, state_derivatives, dummy_states, dummy_derivatives = {};
      list<Pointer<Equation>> constraint_eqns = {}, matched_eqns, unmatched_eqns, new_eqns = {};
      Differentiate.DifferentiationArguments diffArguments;
      Pointer<Differentiate.DifferentiationArguments> diffArguments_ptr;
      VariablePointers candidate_ptrs;
      EquationPointers constraint_ptrs;
      AdjacencyMatrix set_adj;
      Matching set_matching;

      Boolean debug = false;
    algorithm
      // --------------------------------------------------------
      //      1. BASIC INDEX REDUCTION
      // --------------------------------------------------------

      // get all unmatched eqns and state candidates
      for idx in marked_eqns loop
        constraint := ExpandableArray.get(idx, equations.eqArr);
        constraint_eqns := constraint :: constraint_eqns;
        candidates := BEquation.Equation.collectCrefs(Pointer.access(constraint), getStateCandidate);
      end for;
      for cref in candidates loop
        state_candidates := BVariable.getVarPointer(cref) :: state_candidates;
      end for;
      state_candidates := sortCandidates(state_candidates);

      // ToDo: differ between user dumping and developer dumping
      if Flags.isSet(Flags.DUMMY_SELECT) then
        print(StringUtil.headline_1("Index Reduction") + "\n");
        print(StringUtil.headline_4("(" + intString(listLength(state_candidates)) + ") Sorted State Candidates"));
        print("{" + stringDelimitList(list(ComponentRef.toString(BVariable.getVarName(var)) for var in state_candidates), ", ") + "}\n\n");
        print(StringUtil.headline_4("(" + intString(listLength(constraint_eqns)) + ") Constraint Equations"));
        print(stringDelimitList(list(Equation.toString(Pointer.access(eqn)) for eqn in constraint_eqns), "\n") + "\n\n");
      end if;

      // Build differentiation argument structure
      diffArguments := Differentiate.DIFFERENTIATION_ARGUMENTS(
        diffCref        = ComponentRef.EMPTY(),
        new_vars        = {},
        jacobianHT      = NONE(),
        diffType        = NBDifferentiate.DifferentiationType.TIME,
        funcTree        = funcTree,
        diffedFunctions = AvlSetPath.new()
      );
      diffArguments_ptr := Pointer.create(diffArguments);

      if Flags.isSet(Flags.DUMMY_SELECT) then
        print(StringUtil.headline_3("[dummyselect] 1. Differentiate the constraint equations"));
      end if;

      // differentiate all eqns
      for eqn in constraint_eqns loop
        diffed_eqn := Differentiate.differentiateEquationPointer(eqn, diffArguments_ptr);
        new_eqns := diffed_eqn :: new_eqns;
        if Flags.isSet(Flags.DUMMY_SELECT) then
          print("[dummyselect] constraint eqn:\t\t" + Equation.toString(Pointer.access(eqn)) + "\n");
          print("[dummyselect] differentiated eqn:\t" + Equation.toString(Pointer.access(diffed_eqn)) + "\n\n");
        end if;
      end for;
      diffArguments := Pointer.access(diffArguments_ptr);

      // --------------------------------------------------------
      //  2. DUMMY DERIVATIVE
      // --------------------------------------------------------
      candidate_ptrs := VariablePointers.fromList(state_candidates);
      constraint_ptrs := EquationPointers.fromList(constraint_eqns);

      // create adjacency matrix and match with transposed matrix to respect variable priority
      set_adj := AdjacencyMatrix.create(candidate_ptrs, constraint_ptrs, AdjacencyMatrixType.SCALAR, AdjacencyMatrixStrictness.STATE_SELECT);
      set_matching := Matching.regular(set_adj, true, true);

      if debug then
        print(AdjacencyMatrix.toString(set_adj, "Index Reduction"));
        print(Matching.toString(set_matching, "Index Reduction "));
      end if;

      // parse the result of the matching
      (dummy_states, states, matched_eqns, unmatched_eqns) := Matching.getUnmatched(set_matching, candidate_ptrs, constraint_ptrs);

      if Flags.isSet(Flags.DUMMY_SELECT) then
        print(StringUtil.headline_4("(" + intString(listLength(states)) + ") Selected States"));
        print("{" + stringDelimitList(list(ComponentRef.toString(BVariable.getVarName(var)) for var in states), ", ") + "}\n\n");
      end if;

      // --------------------------------------------------------
      //  3. STATIC AND DYNAMIC STATE SELECTION
      // --------------------------------------------------------
      // for both static and dynamic state selection all matched states are regarded dummys
      for dummy in dummy_states loop
        dummy_derivatives := BVariable.makeDummyState(dummy) :: dummy_derivatives;
      end for;

      if listEmpty(unmatched_eqns) then
        // --------------------------------------------------------
        //  4. STATIC STATE SELECTION
        // --------------------------------------------------------
        if Flags.isSet(Flags.DUMMY_SELECT) then
          print(StringUtil.headline_2("\t STATIC STATE SELECTION\n\t(no unmatched equations)"));
        end if;
      else
        // --------------------------------------------------------
        //  5. DYNAMIC STATE SELECTION
        // --------------------------------------------------------
        if Flags.isSet(Flags.DUMMY_SELECT) then
          print(StringUtil.headline_2("\t  DYNAMIC STATE SELECTION\n\t(some unmatched equations)"));
          print(StringUtil.headline_4("(" + intString(listLength(unmatched_eqns)) + ") Remaining Equations"));
          print(stringDelimitList(list(Equation.toString(Pointer.access(eqn)) for eqn in unmatched_eqns), "\n") + "\n\n");
          print(StringUtil.headline_4("(" + intString(listLength(dummy_states)) + ") Remaining State Candidates"));
          print("{" + stringDelimitList(list(ComponentRef.toString(BVariable.getVarName(var)) for var in dummy_states), ", ") + "}\n\n");
        end if;
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because dynamic index reduction is not yet supported."});
        fail();
      end if;

      // --------------------------------------------------------
      //     6. UPDATE VARIABLE AND EQUATION ARRAYS
      // --------------------------------------------------------
      // filter all variables that were created during differentiation for state derivatives
      (state_derivatives, _) := List.extractOnTrue(diffArguments.new_vars, BVariable.isStateDerivative);

      // add all new differentiated variables
      variables := VariablePointers.addList(diffArguments.new_vars, variables);
      // add all dummy states
      variables := VariablePointers.addList(dummy_states, variables);
      // add new equations
      equations := EquationPointers.addList(new_eqns, equations);

      // cleanup varData and expand eqData
      // some algebraics -> states (to states)
      varData := VarData.addTypedList(varData, states, NBVariable.VarData.VarType.STATE);
      // new derivatives (to derivatives)
      varData := VarData.addTypedList(varData, state_derivatives, NBVariable.VarData.VarType.STATE_DER);
      // some states -> dummy states (to algebraics)
      varData := VarData.addTypedList(varData, dummy_states, NBVariable.VarData.VarType.ALGEBRAIC);
      // some derivatives -> dummy derivatives (to algebraics)
      varData := VarData.addTypedList(varData, dummy_derivatives, NBVariable.VarData.VarType.ALGEBRAIC);
      // new equations
      eqData := EqData.addTypedList(eqData, new_eqns, NBEquation.EqData.EqType.CONTINUOUS);

    end main;

  protected
    function getStateCandidate
      input output ComponentRef cref          "the cref to check";
      input Pointer<list<ComponentRef>> acc   "accumulator for relevant crefs";
    protected
      Pointer<Variable> var;
    algorithm
      var := BVariable.getVarPointer(cref);
      if (BVariable.isState(var) or BVariable.isStateDerivative(var) or BVariable.isAlgebraic(var)) then
        Pointer.update(acc, cref :: Pointer.access(acc));
      end if;
    end getStateCandidate;

    function candidatePriority
      "returns the priority of a variable for state selection.
      higher priority -> better chance of getting picked as a state."
      input Pointer<Variable> candidate;
      output Integer prio;
    algorithm
      prio := match Pointer.access(candidate)
        local
          BackendExtension.VariableAttributes attributes;
        case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(attributes = attributes))
        then match BackendExtension.VariableAttributes.getStateSelect(attributes)
          case NFBackendExtension.StateSelect.NEVER   then -200;
          case NFBackendExtension.StateSelect.AVOID   then -100;
          case NFBackendExtension.StateSelect.DEFAULT then 0;
          case NFBackendExtension.StateSelect.PREFER  then 100;
          case NFBackendExtension.StateSelect.ALWAYS  then 200;
                                                      else 0;
        end match;
        else algorithm
        then fail();
      end match;
    end candidatePriority;

    function sortCandidates
      "sorts the state candidates"
      input output list<Pointer<Variable>> candidates;
    protected
      list<tuple<Integer,Pointer<Variable>>> priorities = {};
    algorithm
      for candidate in candidates loop
        priorities := (candidatePriority(candidate), candidate) :: priorities;
      end for;
      priorities := List.sort(priorities, BackendUtil.indexTplGt);
      (_, candidates) := List.unzip(priorities);
    end sortCandidates;
  end IndexReduction;

  encapsulated package Sorting
  public
    import BEquation = NBEquation;
    import NBEquation.EquationPointers;
    import BVariable = NBVariable;
    import NBVariable.VariablePointers;
    import NBCausalize.AdjacencyMatrix;
    import NBCausalize.Matching;
    import StrongComponent = NBStrongComponent;

    function tarjan
      "author: kabdelhak
      Sorting algorithm for directed graphs by Robert E. Tarjan.
      First published in doi:10.1137/0201010"
      input AdjacencyMatrix adj;
      input Matching matching;
      input VariablePointers vars;
      input EquationPointers eqns;
      output list<StrongComponent> comps;
    algorithm
      comps := match (adj, matching)
        local
          list<list<Integer>> comps_indices;

        case (AdjacencyMatrix.SCALAR_ADJACENCY_MATRIX(), Matching.SCALAR_MATCHING()) algorithm
          comps_indices := tarjanScalar(adj.m, matching.var_to_eqn);
          comps := list(StrongComponent.create(idx_lst, matching, vars, eqns) for idx_lst in comps_indices);
        then comps;

        case (AdjacencyMatrix.ARRAY_ADJACENCY_MATRIX(), Matching.ARRAY_MATCHING()) algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array sorting is not yet supported."});
        then fail();

        case (AdjacencyMatrix.EMPTY_ADJACENCY_MATRIX(), Matching.EMPTY_MATCHING()) algorithm
        then {};

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because adjacency matrix and matching have different types."});
        then fail();
      end match;
    end tarjan;

    function tarjanScalar
      "author: lochel, kabdelhak
      This sorting algorithm only considers equations e that have a matched variable v with e = var_to_eqn[v]."
      input array<list<Integer>> m          "normal adjacency matrix";
      input array<Integer> var_to_eqn       "eqn := var_to_eqn[var]";
      output list<list<Integer>> comps = {} "eqn indices";
    protected
      Integer index = 0;
      list<Integer> stack = {};
      array<Integer> number, lowlink;
      array<Boolean> onStack;
      Integer N = arrayLength(var_to_eqn);
      Integer eqn;
    algorithm
      number := arrayCreate(N, -1);
      lowlink := arrayCreate(N, -1);
      onStack := arrayCreate(N, false);

      // loop over all variables and find their component
      for var in 1:N loop
        eqn := var_to_eqn[var];
        if eqn > 0 and number[eqn] == -1 then
          (stack, index, comps) := strongConnect(m, var_to_eqn, eqn, stack, index, number, lowlink, onStack, comps);
        end if;
      end for;

      // free auxiliary arrays
      GC.free(number);
      GC.free(lowlink);
      GC.free(onStack);

      // reverse for correct ordering
      comps := listReverse(comps);
    end tarjanScalar;

    protected function strongConnect
      "author: lochel, kabdelhak"
      input array<list<Integer>> m            "normal adjacency matrix";
      input array<Integer> var_to_eqn         "eqn := var_to_eqn[var]";
      input Integer eqn                       "current equation index";
      input output list<Integer> stack        "equation stack";
      input output Integer index              "component index";
      input array<Integer> number             "auxiliary array";
      input array<Integer> lowlink            "represents the component groups";
      input array<Boolean> onStack            "true if eqn index is on the stack";
      input output list<list<Integer>> comps  "accumulator for components";
    protected
      list<Integer> SCC;
      Integer eqn2;
    algorithm
      // Set the depth index for eqn to the smallest unused index
      arrayUpdate(number, eqn, index);
      arrayUpdate(lowlink, eqn, index);
      arrayUpdate(onStack, eqn, true);
      index := index + 1;
      stack := eqn::stack;

      // Consider successors of eqn
      for eqn2 in predecessors(eqn, m, var_to_eqn) loop
        if number[eqn2] == -1 then
          // Successor eqn2 has not yet been visited; recurse on it
          (stack, index, comps) := strongConnect(m, var_to_eqn, eqn2, stack, index, number, lowlink, onStack, comps);
          arrayUpdate(lowlink, eqn, intMin(lowlink[eqn], lowlink[eqn2]));
        elseif onStack[eqn2] then
          // Successor eqn2 is in the stack and hence in the current SCC
          arrayUpdate(lowlink, eqn, intMin(lowlink[eqn], number[eqn2]));
        end if;
      end for;

      // If eqn is a root node, pop the stack and generate an SCC
      if lowlink[eqn] == number[eqn] then
        eqn2::stack := stack;
        arrayUpdate(onStack, eqn2, false);
        SCC := {eqn2};
        while eqn <> eqn2 loop
          eqn2::stack := stack;
          arrayUpdate(onStack, eqn2, false);
          SCC := eqn2::SCC;
        end while;
        comps := MetaModelica.Dangerous.listReverseInPlace(SCC)::comps;
      end if;
    end strongConnect;

    function predecessors "author: lochel, kabdelhak
      Returns a list of incoming nodes, corresponding
      to the adjacency matrix"
      input Integer idx             "node index to get all predecessors for";
      input array<list<Integer>> m  "normal adjacency matrix";
      input array<Integer> mapping  "maps either var to eqn or eqn to var (matching)";
      output list<Integer> pre_lst  "all predecessors";
    algorithm
      pre_lst := list(mapping[cand] for cand guard(cand > 0 and mapping[cand] <> idx and mapping[cand] > 0) in m[idx]);
    end predecessors;
  end Sorting;

  annotation(__OpenModelica_Interface="backend");
end NBCausalize;
