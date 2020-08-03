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
  import Variable = NFVariable;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import BVariable = NBVariable;
  import Equation = NBEquation.Equation;
  import StrongComponent = NBStrongComponent;
  import System = NBSystem;

  // util imports
  import Error;
  import GC;
  import HashTableCrToInt = NBHashTableCrToInt;
  import StringUtil;

public
  function main extends Module.wrapper;
    input System.SystemType systemType;
  algorithm
    bdae := match (systemType, bdae)
      local
        BackendDAE.BackendDAE qual;
        list<System.System> systems;

      case (System.SystemType.ODE, qual as BackendDAE.BDAE(ode = systems))
        algorithm
          qual.ode := List.map(systems, causalizeScalar);
      then qual;

      case (System.SystemType.INIT, qual as BackendDAE.BDAE(init = systems))
        algorithm
          qual.init := List.map(systems, causalizeScalar);
      then qual;

      case (System.SystemType.DAE, qual as BackendDAE.BDAE(dae = SOME(systems)))
        algorithm
          qual.dae := SOME(List.map(systems, causalizeDAEMode));
      then qual;

    else algorithm
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed with system type " + System.System.systemTypeString(systemType) + "!"});
    then fail();

    end match;
  end main;

protected
  function causalizeScalar extends Module.causalizeInterface;
  protected
    list<Pointer<Variable>> var_lst;
    list<Pointer<Equation>> eqn_lst;
    AdjacencyMatrix adj;
    Matching matching;
    list<StrongComponent> comps;
    StrongComponent comp;
  algorithm
    // create scalar adjacency matrix for now
    adj := AdjacencyMatrix.create(system.unknowns, system.equations, AdjacencyMatrixType.SCALAR);
    matching := Matching.regular(adj);
    comps := Sorting.tarjan(adj, matching, system.unknowns, system.equations);
    if Flags.isSet(Flags.BLT_DUMP) then
      print(AdjacencyMatrix.toString(adj, "Causalize "));
      print(Matching.toString(matching, "Causalize"));
    end if;

    // For now only create one block containing everything
    //var_lst := BVariable.VariablePointers.toList(system.unknowns);
    //eqn_lst := BEquation.EquationPointers.toList(system.equations);

    //comp := StrongComponent.ALGEBRAIC_LOOP(var_lst, eqn_lst, NONE(), false);
    system.strongComponents := SOME(listArray(comps));
  end causalizeScalar;

  function causalizeDAEMode extends Module.causalizeInterface;
  protected
    Pointer<list<StrongComponent>> acc = Pointer.create({});
  algorithm
    // create all components as residuals for now
    // ToDo: use tearing to get inner/tmp equations
    BEquation.EquationPointers.mapPtr(system.equations, function StrongComponent.makeDAEModeResidualTraverse(acc = acc));
    system.strongComponents := SOME(listArray(listReverse(Pointer.access(acc))));
  end causalizeDAEMode;

public
  uniontype AdjacencyMatrix
    record ARRAY_ADJACENCY_MATRIX
      AdjacencyMatrixQuarter m;
      AdjacencyMatrixQuarterT mT;
      /* Maybe add optional markings here */
    end ARRAY_ADJACENCY_MATRIX;

    record SCALAR_ADJACENCY_MATRIX
      array<list<Integer>> m;
      array<list<Integer>> mT;
    end SCALAR_ADJACENCY_MATRIX;

    function create
      input BVariable.VariablePointers vars;
      input BEquation.EquationPointers eqs;
      input AdjacencyMatrixType ty;
      output AdjacencyMatrix adj;
    algorithm
      adj := match ty
        case AdjacencyMatrixType.SCALAR then createScalar(vars, eqs);
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
        local
          AdjacencyMatrix qual;
        case qual as ARRAY_ADJACENCY_MATRIX() then str + "\n ARRAY NOT YET SUPPORTED \n";
        case qual as SCALAR_ADJACENCY_MATRIX() algorithm
          if arrayLength(qual.m) > 0 then
            str := str + StringUtil.headline_4("Normal Adjacency Matrix (row = equation)");
            str := str + toStringSingle(qual.m);
          end if;
          str := str + "\n";
          if arrayLength(qual.mT) > 0 then
            str := str + StringUtil.headline_4("Transposed Adjacency Matrix (row = variable)");
            str := str + toStringSingle(qual.mT);
          end if;
          str := str + "\n";
        then str;
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
      input BVariable.VariablePointers vars;
      input BEquation.EquationPointers eqs;
      output AdjacencyMatrix adj;
    protected
      list<ComponentRef> cref_lst, dependencies;
      list<Pointer<BEquation.Equation>> eqn_lst;
      NBHashTableCrToInt.HashTable ht;
      array<list<Integer>> m, mT;
      Integer var_idx = 1, eqn_idx = 1;
    algorithm
      cref_lst := BVariable.VariablePointers.getVarNames(vars);
      eqn_lst := BEquation.EquationPointers.toList(eqs);
      // create a sufficiant big hash table and add all vars names with index for lookup
      // kabdelhak: this should replace the crefIndex list in variable vector at some point!
      ht := NBHashTableCrToInt.empty(listLength(cref_lst));
      for cref in cref_lst loop
        ht := BaseHashTable.add((cref, var_idx), ht);
        var_idx := var_idx + 1;
      end for;

      // create empty adjacency matrix and traverse equations to fill it
      m := arrayCreate(listLength(eqn_lst), {});
      for eqn in eqn_lst loop
        dependencies := BEquation.Equation.collectCrefs(Pointer.access(eqn), function getDependentCref(ht = ht));
        m[eqn_idx] := getDependentCrefIndices(dependencies, ht);
        eqn_idx := eqn_idx + 1;
      end for;
      mT := transposeScalar(m, listLength(cref_lst));
      adj := SCALAR_ADJACENCY_MATRIX(m, mT);
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
            mT[idx] := row :: mT[idx];
          else
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for variable index " + intString(idx) + ".
              The variables have to be dense (without empty spaces) for this to work!"});
          end try;
        end for;
      end for;
      // sort the transposed matrix
      for row in 1:arrayLength(mT) loop
        mT[row] := List.sort(mT[row], intGt);
      end for;
    end transposeScalar;

    function getDependentCref
      input output ComponentRef cref          "the cref to check";
      input Pointer<list<ComponentRef>> acc   "accumulator for relevant crefs";
      input NBHashTableCrToInt.HashTable ht   "hash table to check for relevance";
    algorithm
      if BaseHashTable.hasKey(cref, ht) then
        Pointer.update(acc, cref :: Pointer.access(acc));
      end if;
    end getDependentCref;

    function getDependentCrefIndices
      input list<ComponentRef> dependencies   "dependent var crefs";
      input NBHashTableCrToInt.HashTable ht   "hash table to check for relevance";
      output list<Integer> indices = {};
    algorithm
      for cref in dependencies loop
        indices := BaseHashTable.get(cref, ht) :: indices;
      end for;
      // remove duplicates and sort
      indices := List.sort(List.unique(indices), intGt);
    end getDependentCrefIndices;
  end AdjacencyMatrix;

  type AdjacencyMatrixType = enumeration(SCALAR, ARRAY);

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

    function toString
      input Matching matching;
      input output String str = "";
    algorithm
      str := StringUtil.headline_2(str + "Matching") + "\n";
      str := match matching
        local
          Matching qual;
        case qual as SCALAR_MATCHING() algorithm
          str := str + toStringSingle(qual.var_to_eqn, false) + "\n";
          str := str + toStringSingle(qual.eqn_to_var, true) + "\n";
        then str;
        case qual as ARRAY_MATCHING() algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array matching is not yet supported."});
        then fail();
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
      output Matching matching;
    algorithm
      matching := match adj
        local
          AdjacencyMatrix qual;
        case qual as SCALAR_ADJACENCY_MATRIX() then scalarRegular(qual.m, qual.mT);
        case qual as ARRAY_ADJACENCY_MATRIX() algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array matching is not yet supported."});
        then fail();
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
        then fail();
      end match;
    end regular;

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

    function scalarRegular
      input array<list<Integer>> m;
      input array<list<Integer>> mT;
      output Matching matching;
    protected
      Integer nVars = arrayLength(mT), nEqns = arrayLength(mT);
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
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the system is structurally singular. Index Reduction is not yet supported"});
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
      GC.free(var_marks);
      GC.free(eqn_marks);

      // create the matching structure
      matching := SCALAR_MATCHING(var_to_eqn, eqn_to_var);
    end scalarRegular;

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

  encapsulated package Sorting
  public
    import BEquation = NBEquation;
    import BVariable = NBVariable;
    import NBCausalize.AdjacencyMatrix;
    import NBCausalize.Matching;
    import StrongComponent = NBStrongComponent;

    function tarjan
      "author: kabdelhak
      Sorting algorithm for directed graphs by Robert E. Tarjan.
      First published in doi:10.1137/0201010"
      input AdjacencyMatrix adj;
      input Matching matching;
      input BVariable.VariablePointers vars;
      input BEquation.EquationPointers eqns;
      output list<StrongComponent> comps;
    algorithm
      comps := match (adj, matching)
        local
          AdjacencyMatrix qualAdj;
          Matching qualMatching;
          list<list<Integer>> comps_indices;

        case (qualAdj as AdjacencyMatrix.SCALAR_ADJACENCY_MATRIX(), qualMatching as Matching.SCALAR_MATCHING()) algorithm
          comps_indices := tarjanScalar(qualAdj.m, qualMatching.var_to_eqn);
          comps := list(StrongComponent.create(idx_lst, matching, vars, eqns) for idx_lst in comps_indices);
        then comps;

        case (qualAdj as AdjacencyMatrix.ARRAY_ADJACENCY_MATRIX(), qualMatching as Matching.ARRAY_MATCHING()) algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array sorting is not yet supported."});
        then fail();

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
