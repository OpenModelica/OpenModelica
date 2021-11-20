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
encapsulated package NBAdjacency
"file:        NBAdjacency.mo
 package:     NBAdjacency
 description: This file contains the functions which will create adjacency matrices.
"
public
  // self import
  import Adjacency = NBAdjacency;

protected
  // NF imports
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import FunctionTree = NFFlatten.FunctionTree;
  import SimplifyExp = NFSimplifyExp;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // NB imports
  import Differentiate = NBDifferentiate;
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationAttributes, EquationPointers, Iterator};
  import Replacements = NBReplacements;
  import BVariable = NBVariable;
  import NBVariable.VariablePointers;

  // Util import
  import BackendUtil = NBBackendUtil;
  import BuiltinSystem = System;

  // SetBased Graph imports
  import SBGraph.BipartiteIncidenceList;
  import SBGraph.VertexDescriptor;
  import SBGraph.SetType;
  import SBInterval;
  import SBMultiInterval;
  import SBPWLinearMap;
  import SBSet;
  import NBGraphUtil.{SetVertex, SetEdge};

public
  type MatrixType        = enumeration(SCALAR, ARRAY, PSEUDO);
  type MatrixStrictness  = enumeration(FULL, LINEAR, STATE_SELECT, INIT);
  type BipartiteGraph    = BipartiteIncidenceList<SetVertex, SetEdge>;

  uniontype Mapping
    record MAPPING
      array<Integer> eqn_StA                  "eqn: scal_idx -> arr_idx";
      array<Integer> var_StA                  "var: scal_idx -> arr_idx";
      array<tuple<Integer,Integer>> eqn_AtS   "eqn: arr_idx -> start_idx/length";
      array<tuple<Integer,Integer>> var_AtS   "var: arr_idx -> start_idx/length";
    end MAPPING;

    function toString
      input Mapping mapping;
      output String str;
    protected
      Integer start, size;
    algorithm
      str := StringUtil.headline_4("Equation Index Mapping (ARR) -> START | SIZE");
      for i in 1:arrayLength(mapping.eqn_AtS) loop
        (start, size) := mapping.eqn_AtS[i];
        str := str + "(" + intString(i) + ")\t" + intString(start) + " | " + intString(size) + "\n";
      end for;
      str := str + StringUtil.headline_4("Variable Index Mapping (ARR) -> START | SIZE");
      for i in 1:arrayLength(mapping.var_AtS) loop
        (start, size) := mapping.var_AtS[i];
        str := str + "(" + intString(i) + ")\t" + intString(start) + " | " + intString(size) + "\n";
      end for;
    end toString;

    function getEqnFirst
      input Integer scal_idx;
      input Mapping mapping;
      output Integer first_idx;
    protected
      Integer arr_idx;
    algorithm
      arr_idx := mapping.eqn_StA[scal_idx];
      (first_idx, _) := mapping.eqn_AtS[arr_idx];
    end getEqnFirst;

    function getVarFirst
      input Integer scal_idx;
      input Mapping mapping;
      output Integer first_idx;
    algorithm
      (first_idx, _) := mapping.var_AtS[mapping.var_StA[scal_idx]];
    end getVarFirst;
  end Mapping;

  uniontype CausalizeModes
    record CAUSALIZE_MODES
      "for-loop reconstruction information"
      array<array<Integer>> mode_to_var       "scal_eqn:  mode idx -> var";
      array<array<ComponentRef>> mode_to_cref "arr_eqn:   mode idx -> cref to solve for";
    end CAUSALIZE_MODES;

    function contains
      "checks if there is a mode for this eqn array index"
      input Integer eqn_scal_idx;
      input CausalizeModes modes;
      output Boolean b = not arrayEmpty(arrayGet(modes.mode_to_var, eqn_scal_idx));
    end contains;

    function get
      "returns the proper mode for an eqn-var index tuple"
      input Integer eqn_scal_idx;
      input Integer var_scal_idx;
      input CausalizeModes modes;
      output Integer mode = -1;
    protected
      array<Integer> mtv = arrayGet(modes.mode_to_var, eqn_scal_idx);
    algorithm
      for i in 1:arrayLength(mtv) loop
        if mtv[i] == var_scal_idx then
          mode := i;
          return;
        end if;
      end for;
    end get;
  end CausalizeModes;

  uniontype Matrix
    record ARRAY_ADJACENCY_MATRIX
      "no transposed set matrix needed since the graph represents all vertices equally"
      BipartiteGraph graph                        "set based graph";
      UnorderedMap<SetVertex, Integer> vertexMap  "map to get the vertex index";
      UnorderedMap<SetEdge, Integer> edgeMap      "map to get the edge index";
      MatrixStrictness st;
      /* Maybe add optional markings here */
    end ARRAY_ADJACENCY_MATRIX;

    record PSEUDO_ARRAY_ADJACENCY_MATRIX
      array<list<Integer>> m        "eqn -> list<var>";
      array<list<Integer>> mT       "var -> list<eqn>";
      Mapping mapping               "index mapping scalar <-> array";
      CausalizeModes modes          "for-loop reconstruction information";
      MatrixStrictness st;
    end PSEUDO_ARRAY_ADJACENCY_MATRIX;

    record SCALAR_ADJACENCY_MATRIX
      array<list<Integer>> m        "eqn -> list<var>";
      array<list<Integer>> mT       "var -> list<eqn>";
      MatrixStrictness st;
    end SCALAR_ADJACENCY_MATRIX;

    record EMPTY_ADJACENCY_MATRIX
    end EMPTY_ADJACENCY_MATRIX;

    function create
      input VariablePointers vars;
      input EquationPointers eqs;
      input MatrixType ty;
      input MatrixStrictness st = MatrixStrictness.FULL;
      output Matrix adj;
      input output Option<FunctionTree> funcTree = NONE() "only needed for LINEAR without existing derivatives";
    algorithm
      (adj, funcTree) := match ty
        case MatrixType.SCALAR then createScalar(vars, eqs, st, funcTree);
        case MatrixType.ARRAY  then createArray(vars, eqs, st, funcTree);
        case MatrixType.PSEUDO then createPseudoArray(vars, eqs, st, funcTree);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown adjacency matrix type."});
        then fail();
      end match;
    end create;

    function update
      "Updates specified rows of the adjacency matrix.
      Updates everything by default and if the index
      list is equal to {-1}."
      input output Matrix adj;
      input VariablePointers vars;
      input EquationPointers eqs;
      input list<Integer> idx_lst = {-1};
      input output Option<FunctionTree> funcTree = NONE() "only needed for LINEAR without existing derivatives";
    algorithm
      (adj, funcTree) := match (adj, idx_lst)
        local
          array<list<Integer>> m, mT;
        case (SCALAR_ADJACENCY_MATRIX(), {-1})          then create(vars, eqs, MatrixType.SCALAR, adj.st);
        case (ARRAY_ADJACENCY_MATRIX(), {-1})           then create(vars, eqs, MatrixType.ARRAY, adj.st);
        case (PSEUDO_ARRAY_ADJACENCY_MATRIX(), {-1})    then create(vars, eqs, MatrixType.PSEUDO, adj.st);

        case (SCALAR_ADJACENCY_MATRIX(m = m, mT = mT), _) algorithm
          (m, mT) := updateScalar(m, mT, adj.st, vars, eqs, idx_lst, funcTree);
          adj.m := m;
          adj.mT := mT;
        then (adj, funcTree);

        case (PSEUDO_ARRAY_ADJACENCY_MATRIX(), _) algorithm
          // ToDo
          print("NOT IMPLEMENTED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
        then (adj, funcTree);

        case (ARRAY_ADJACENCY_MATRIX(), _) algorithm
          // ToDo
        then (adj, funcTree);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown adjacency matrix type."});
        then fail();
      end match;
    end update;

    function toString
      input Matrix adj;
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

        case PSEUDO_ARRAY_ADJACENCY_MATRIX() algorithm
          if arrayLength(adj.m) > 0 then
            str := str + StringUtil.headline_4("Normal Adjacency Matrix (row = equation)");
            str := str + toStringSingle(adj.m);
          end if;
          str := str + "\n";
          if arrayLength(adj.mT) > 0 then
            str := str + StringUtil.headline_4("Transposed Adjacency Matrix (row = variable)");
            str := str + toStringSingle(adj.mT);
          end if;
          str := str + "\n" + Mapping.toString(adj.mapping);
        then str;

        case EMPTY_ADJACENCY_MATRIX() then str + StringUtil.headline_4("Empty Adjacency Matrix") + "\n";
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown adjacency matrix type."});
        then fail();
      end match;
    end toString;

    function getMappingOpt
      input Matrix adj;
      output Option<Mapping> mapping;
    algorithm
      mapping := match adj
        case PSEUDO_ARRAY_ADJACENCY_MATRIX() then SOME(adj.mapping);
                                             else NONE();
      end match;
    end getMappingOpt;

    function nonZeroCount
      input Matrix adj;
      output Integer count;
    algorithm
      count := match adj
        case PSEUDO_ARRAY_ADJACENCY_MATRIX()  then BackendUtil.countElem(adj.m);
        case SCALAR_ADJACENCY_MATRIX()        then BackendUtil.countElem(adj.m);
        case EMPTY_ADJACENCY_MATRIX()         then 0;
        case ARRAY_ADJACENCY_MATRIX() algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array adjacency matrix is not jet supported."});
        then fail();
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown matrix type."});
        then fail();
      end match;
    end nonZeroCount;

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
      input MatrixStrictness st = MatrixStrictness.FULL;
      output Matrix adj;
      input output Option<FunctionTree> funcTree = NONE() "only needed for LINEAR without existing derivatives";
    protected
      Pointer<Differentiate.DifferentiationArguments> diffArgs_ptr;
      Differentiate.DifferentiationArguments diffArgs;
      list<Pointer<BEquation.Equation>> eqn_lst;
      array<list<Integer>> m, mT;
      Integer eqn_idx = 1;
      array<array<Integer>> mode_to_var         = arrayCreate(0,arrayCreate(0,0)) "modes only necessary for pseudo array adjacency matrices";
      array<array<ComponentRef>> mode_to_cref   = arrayCreate(0,arrayCreate(0,ComponentRef.EMPTY())) "modes only necessary for pseudo array adjacency matrices";
    algorithm
      if ExpandableArray.getNumberOfElements(vars.varArr) > 0 or ExpandableArray.getNumberOfElements(eqs.eqArr) > 0 then
        if Util.isSome(funcTree) then
          diffArgs_ptr := Pointer.create(Differentiate.DifferentiationArguments.default(NBDifferentiate.DifferentiationType.TIME, Util.getOption(funcTree)));
        end if;

        eqn_lst := EquationPointers.toList(eqs);
        // create empty adjacency matrix and traverse equations to fill it
        m := arrayCreate(listLength(eqn_lst), {});
        for eqn_ptr in eqn_lst loop
          createRow(eqn_ptr, diffArgs_ptr, st, vars, m, mode_to_var, mode_to_cref, NONE(), eqn_idx, false, funcTree);
          eqn_idx := eqn_idx + 1;
        end for;

        // also sorts the matrix
        mT := transposeScalar(m, ExpandableArray.getLastUsedIndex(vars.varArr));

        // after proper sorting fixup the indices for STATE_SELECT and INIT
        if st > MatrixStrictness.LINEAR then
          m := absoluteMatrix(m);
          mT := absoluteMatrix(mT);
        end if;
        if Util.isSome(funcTree) then
          diffArgs := Pointer.access(diffArgs_ptr);
          funcTree := SOME(diffArgs.funcTree);
        end if;

        adj := SCALAR_ADJACENCY_MATRIX(m, mT, st);
      else
        adj := EMPTY_ADJACENCY_MATRIX();
      end if;
    end createScalar;

    function updateScalar
      input output array<list<Integer>> m;
      input output array<list<Integer>> mT;
      input MatrixStrictness st;
      input VariablePointers vars;
      input EquationPointers eqns;
      input list<Integer> idx_lst;
      input output Option<FunctionTree> funcTree = NONE() "only needed for LINEAR without existing derivatives";
    protected
      Pointer<Differentiate.DifferentiationArguments> diffArgs_ptr;
      Differentiate.DifferentiationArguments diffArgs;
      array<array<Integer>> mode_to_var         = arrayCreate(0,arrayCreate(0,0)) "modes only necessary for pseudo array adjacency matrices";
      array<array<ComponentRef>> mode_to_cref   = arrayCreate(0,arrayCreate(0,ComponentRef.EMPTY())) "modes only necessary for pseudo array adjacency matrices";
    algorithm
      if Util.isSome(funcTree) then
        diffArgs_ptr := Pointer.create(Differentiate.DifferentiationArguments.default(NBDifferentiate.DifferentiationType.TIME, Util.getOption(funcTree)));
      end if;

      for i in idx_lst loop
        createRow(EquationPointers.getEqnAt(eqns, i), diffArgs_ptr, st, vars, m, mode_to_var, mode_to_cref, NONE(), i, false, funcTree);
      end for;

      // also sorts the matrix
      mT := transposeScalar(m, ExpandableArray.getLastUsedIndex(vars.varArr));

      // after proper sorting fixup the indices for STATE_SELECT and INIT
      if st > MatrixStrictness.LINEAR then
        m := absoluteMatrix(m);
        mT := absoluteMatrix(mT);
      end if;
      if Util.isSome(funcTree) then
        diffArgs := Pointer.access(diffArgs_ptr);
        funcTree := SOME(diffArgs.funcTree);
      end if;
    end updateScalar;

    function createRow
      input Pointer<Equation> eqn_ptr;
      input Pointer<Differentiate.DifferentiationArguments> diffArgs_ptr;
      input MatrixStrictness st;
      input VariablePointers vars;
      input array<list<Integer>> m;
      input array<array<Integer>> mode_to_var;
      input array<array<ComponentRef>> mode_to_cref;
      input Option<Mapping> mapping_opt;
      input Integer eqn_idx;
      input Boolean pseudo = false;
      input Option<FunctionTree> funcTree = NONE() "only needed for LINEAR without existing derivatives";
    protected
      Equation eqn;
      list<ComponentRef> dependencies, state_dependencies, nonlinear_dependencies;
      BEquation.EquationAttributes attr;
      Pointer<Equation> derivative;
    algorithm
      eqn := Pointer.access(eqn_ptr);
      // possibly adapt for algorithms
      dependencies := BEquation.Equation.collectCrefs(eqn, function getDependentCref(map = vars.map, pseudo = pseudo));

        // INIT
      if (st == MatrixStrictness.INIT) then
        // for initialization all regular rules apply but states have to be
        // sorted to be at the end
        (state_dependencies, dependencies) := List.extractOnTrue(dependencies, function BVariable.checkCref(func = BVariable.isState));
        fillMatrix(eqn, m, mode_to_var, mode_to_cref, mapping_opt, eqn_idx, state_dependencies, vars.map, true, pseudo);

      // LINEAR and STATE SELECT
      elseif (st > MatrixStrictness.FULL) then
        attr := Equation.getAttributes(eqn);
        if Util.isSome(attr.derivative) then
          derivative := Util.getOption(attr.derivative);
        elseif Util.isSome(funcTree) then
          derivative := Differentiate.differentiateEquationPointer(eqn_ptr, diffArgs_ptr);
        else
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because no derivative is saved and no function tree is given for linear adjacency matrix!"});
        end if;
        // if we only want linear dependencies, try to look if there is a derivative saved. remove all dependencies
        // of that equation because those are the nonlinear ones.
        // for now fail if there is no derivative, possible fallback: differentiate eq and save it
        nonlinear_dependencies := BEquation.Equation.collectCrefs(Pointer.access(derivative), function getDependentCref(map = vars.map, pseudo = pseudo));
        dependencies := List.setDifferenceOnTrue(dependencies, nonlinear_dependencies, ComponentRef.isEqual);
        if st == MatrixStrictness.STATE_SELECT then
          // if we are preparing for state selection we only search for linear occurences. One exception
          // are StateSelect.NEVER variables, which are allowed to appear nonlinear. but they have to be
          // the last checked option, so they have a negative index and are afterwards sorted to be at the end
          // of the list.
          (nonlinear_dependencies, _) := List.extractOnTrue(nonlinear_dependencies,
            function BVariable.checkCref(func = function BVariable.isStateSelect(stateSelect = NFBackendExtension.StateSelect.NEVER)));
          fillMatrix(eqn, m, mode_to_var, mode_to_cref, mapping_opt, eqn_idx, nonlinear_dependencies, vars.map, true, pseudo);
        end if;
      end if;

      // create the actual matrix row(s).
      fillMatrix(eqn, m, mode_to_var, mode_to_cref, mapping_opt, eqn_idx, dependencies, vars.map, false, pseudo);
    end createRow;

    function fillMatrix
      "fills one or more rows (depending on equation size) of matrix m, starting from eqn_idx.
      Appends because STATE_SELECT and INIT add matrix entries in two steps to induce a specific ordering.
      For psuedo array matching: also fills mode_to_var."
      input Equation eqn;
      input array<list<Integer>> m;
      input array<array<Integer>> mode_to_var;
      input array<array<ComponentRef>> mode_to_cref;
      input Option<Mapping> mapping_opt;
      input Integer eqn_arr_idx;
      input list<ComponentRef> dependencies         "dependent var crefs";
      input UnorderedMap<ComponentRef, Integer> map "hash table to check for relevance";
      input Boolean negate;
      input Boolean pseudo;
    protected
      array<list<Integer>> m_part;
      array<array<Integer>> mode_to_var_part;
      Integer eqn_scal_idx, eqn_size;
      list<ComponentRef> unique_dependencies = List.unique(list(ComponentRef.simplifySubscripts(dep) for dep in dependencies)); // ToDo: maybe bottleneck! test this for efficiency
    algorithm
      _ := match (eqn, mapping_opt)
        local
          Mapping mapping;
          list<Integer> row;

        case (Equation.FOR_EQUATION(), SOME(mapping)) guard(pseudo) algorithm
          // get expanded matrix rows
          (eqn_scal_idx, eqn_size) := mapping.eqn_AtS[eqn_arr_idx];
          (m_part, mode_to_var_part) := getDependentCrefIndicesPseudoFor(
            dependencies  = unique_dependencies,
            map           = map,
            mapping       = mapping,
            iter          = eqn.iter,
            eqn_arr_idx   = eqn_arr_idx,
            negate        = negate
          );
          // check for arrayLength(m_part) == eqn_size ?

          // add matrix rows to correct locations
          for i in 1:arrayLength(m_part) loop
            arrayUpdate(m, eqn_scal_idx+(i-1), listAppend(m_part[i], m[eqn_scal_idx+(i-1)]));
          end for;

          // create scalar mode idx to variable mapping
          for i in 1:arrayLength(mode_to_var_part) loop
            arrayUpdate(mode_to_var, eqn_scal_idx+(i-1), arrayAppend(mode_to_var_part[i], mode_to_var[eqn_scal_idx+(i-1)]));
          end for;

          // create array mode to cref mapping
          arrayUpdate(mode_to_cref, eqn_arr_idx, arrayAppend(listArray(unique_dependencies), mode_to_cref[eqn_arr_idx]));
        then ();

        case (Equation.ARRAY_EQUATION(), SOME(mapping)) guard(pseudo) algorithm
          (eqn_scal_idx, eqn_size) := mapping.eqn_AtS[eqn_arr_idx];
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array equations are not yet supported:\n"
            + Equation.toString(eqn)});
        then fail();

        case (Equation.RECORD_EQUATION(), SOME(mapping)) guard(pseudo) algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because record equations are not yet supported:\n"
            + Equation.toString(eqn)});
        then fail();

        case (Equation.ALGORITHM(), SOME(mapping)) guard(pseudo) algorithm
          (eqn_scal_idx, eqn_size) := mapping.eqn_AtS[eqn_arr_idx];
          row := getDependentCrefIndices(unique_dependencies, map, negate); //prb worng
          for i in eqn_scal_idx:eqn_scal_idx+eqn_size-1 loop
            arrayUpdate(m, i, listAppend(row, m[i]));
          end for;
        then ();

        case (_, SOME(mapping)) guard(pseudo) algorithm
          (eqn_scal_idx, _) := mapping.eqn_AtS[eqn_arr_idx];
          row := getDependentCrefIndicesPseudo(unique_dependencies, map, mapping, negate);
          arrayUpdate(m, eqn_scal_idx, listAppend(row, m[eqn_scal_idx]));
        then ();

        case (_, NONE()) guard(pseudo) algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array<->scalar index mapping was not provided for pseudo adjacency matrix:\n"
            + Equation.toString(eqn)});
        then fail();

        case (Equation.FOR_EQUATION(), _) algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because for-loop should be flattened for scalar adjacency matrix:\n"
            + Equation.toString(eqn)});
        then fail();

        else algorithm
          row := getDependentCrefIndices(unique_dependencies, map, negate);
          arrayUpdate(m, eqn_arr_idx, listAppend(row, m[eqn_arr_idx]));
        then ();
      end match;
    end fillMatrix;

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

    function createArray
      input VariablePointers vars;
      input EquationPointers eqs;
      input MatrixStrictness st = MatrixStrictness.FULL;
      output Matrix adj;
      input output Option<FunctionTree> funcTree = NONE() "only needed for LINEAR without existing derivatives";
    protected
      BipartiteIncidenceList<SetVertex, SetEdge> graph;
      Pointer<Integer> max_dim = Pointer.create(1);
      Vector<Integer> vCount, eCount;
      UnorderedMap<SetVertex, Integer> vertexMap;
      UnorderedMap<SetEdge, Integer> edgeMap;
    algorithm
      // reset unique tick index to 0
      BuiltinSystem.tmpTickReset(0);

      // create empty set based graph and map
      graph := BipartiteIncidenceList.new(SetVertex.isEqual, SetEdge.isEqual, SetVertex.toString, SetEdge.toString);
      vertexMap := UnorderedMap.new<Integer>(SetVertex.hash, SetVertex.isEqual, VariablePointers.size(vars) + EquationPointers.size(eqs));
      edgeMap := UnorderedMap.new<Integer>(SetEdge.hash, SetEdge.isEqual, VariablePointers.size(vars) + EquationPointers.size(eqs)); // make better size approx here

      // find maximum number of dimensions
      VariablePointers.mapPtr(vars, function maxDimTraverse(max_dim = max_dim));
      EquationPointers.mapRes(eqs, function maxDimTraverse(max_dim = max_dim)); // maybe unnecessary?
      vCount := Vector.newFill(Pointer.access(max_dim), 1);
      eCount := Vector.newFill(Pointer.access(max_dim), 1);

      // create vertices for variables
      VariablePointers.mapPtr(vars, function SetVertex.createTraverse(graph = graph, vCount = vCount, ST = SetType.U, vertexMap = vertexMap));

      // create vertices for equations and create edges
      EquationPointers.map(eqs, function SetEdge.fromEquation(
        graph       = graph,
        vCount      = vCount,
        eCount      = eCount,
        map         = vars.map,
        vertexMap   = vertexMap,
        edgeMap     = edgeMap,
        eqn_tpl_opt = NONE()
      ));

      if Flags.isSet(Flags.DUMP_SET_BASED_GRAPHS) then
        print(BipartiteIncidenceList.toString(graph));
      end if;

      adj := ARRAY_ADJACENCY_MATRIX(graph, vertexMap, edgeMap, st);
    end createArray;

    function createPseudoArray
      input VariablePointers vars;
      input EquationPointers eqs;
      input MatrixStrictness st = MatrixStrictness.FULL;
      output Matrix adj;
      input output Option<FunctionTree> funcTree = NONE() "only needed for LINEAR without existing derivatives";
    protected
      Pointer<Differentiate.DifferentiationArguments> diffArgs_ptr;
      Differentiate.DifferentiationArguments diffArgs;
      list<Pointer<BEquation.Equation>> eqn_lst;
      list<Pointer<Variable>> var_lst;
      array<list<Integer>> m, mT;
      array<Integer> eqn_StA, var_StA;
      array<tuple<Integer,Integer>> eqn_AtS, var_AtS;
      Integer eqn_scalar_size, var_scalar_size, size;
      Integer eqn_idx_scal = 1, eqn_idx_arr = 1, var_idx_scal = 1, var_idx_arr = 1;
      array<array<Integer>> mode_to_var                                               "scal_eqn:  mode idx -> var";
      array<array<ComponentRef>> mode_to_cref                                         "arr_eqn:   mode idx -> cref to solve for";
      Mapping mapping                                                                 "scalar <-> array index mapping";
      CausalizeModes modes                                                            "for loop reconstruction information";
    algorithm
      if ExpandableArray.getNumberOfElements(vars.varArr) > 0 or ExpandableArray.getNumberOfElements(eqs.eqArr) > 0 then
        if Util.isSome(funcTree) then
          diffArgs_ptr := Pointer.create(Differentiate.DifferentiationArguments.default(NBDifferentiate.DifferentiationType.TIME, Util.getOption(funcTree)));
        end if;

        // prepare the mappings
        eqn_lst := EquationPointers.toList(eqs);
        var_lst := VariablePointers.toList(vars);
        eqn_scalar_size := sum(array(Equation.size(eqn) for eqn in eqn_lst));
        var_scalar_size := sum(array(BVariable.size(var) for var in var_lst));
        eqn_AtS := arrayCreate(EquationPointers.size(eqs), (-1, -1));
        var_AtS := arrayCreate(VariablePointers.size(vars), (-1, -1));
        eqn_StA := arrayCreate(eqn_scalar_size, -1);
        var_StA := arrayCreate(var_scalar_size, -1);

        // fill variable mapping
        for var_ptr in var_lst loop
          size := BVariable.size(var_ptr);
          var_AtS[var_idx_arr] := (var_idx_scal, size);
          for i in var_idx_scal:var_idx_scal+size-1 loop
            var_StA[i] := var_idx_arr;
          end for;
          var_idx_scal := var_idx_scal + size;
          var_idx_arr := var_idx_arr + 1;
        end for;

        // fill equation mapping
        for eqn_ptr in eqn_lst loop
          size := Equation.size(eqn_ptr);
          eqn_AtS[eqn_idx_arr] := (eqn_idx_scal, size);
          for i in eqn_idx_scal:eqn_idx_scal+size-1 loop
            eqn_StA[i] := eqn_idx_arr;
          end for;
          eqn_idx_scal := eqn_idx_scal + size;
          eqn_idx_arr := eqn_idx_arr + 1;
        end for;

        // compile mapping
        mapping := MAPPING(eqn_StA, var_StA, eqn_AtS, var_AtS);
        // create empty adjacency matrix and traverse equations to fill it
        m := arrayCreate(eqn_scalar_size, {});
        // create empty for-loop reconstruction information
        mode_to_var   := arrayCreate(eqn_scalar_size, arrayCreate(0,0));
        mode_to_cref  := arrayCreate(EquationPointers.size(eqs), arrayCreate(0,ComponentRef.EMPTY()));

        eqn_idx_arr := 1;
        for eqn_ptr in eqn_lst loop
          createRow(eqn_ptr, diffArgs_ptr, st, vars, m, mode_to_var, mode_to_cref, SOME(mapping), eqn_idx_arr, true, funcTree);
          eqn_idx_arr := eqn_idx_arr + 1;
        end for;

        modes := CAUSALIZE_MODES(mode_to_var, mode_to_cref);

        // also sorts the matrix
        mT := transposeScalar(m, var_scalar_size);

        // after proper sorting fixup the indices for STATE_SELECT and INIT
        if st > MatrixStrictness.LINEAR then
          m := absoluteMatrix(m);
          mT := absoluteMatrix(mT);
        end if;
        if Util.isSome(funcTree) then
          diffArgs := Pointer.access(diffArgs_ptr);
          funcTree := SOME(diffArgs.funcTree);
        end if;

        adj := PSEUDO_ARRAY_ADJACENCY_MATRIX(m, mT, mapping, modes, st);
      else
        adj := EMPTY_ADJACENCY_MATRIX();
      end if;
    end createPseudoArray;

    function maxDimTraverse
      input Pointer<Variable> var_ptr;
      input Pointer<Integer> max_dim;
    protected
      Integer dim_size;
    algorithm
      dim_size := listLength(BVariable.getDimensions(var_ptr));
      if Pointer.access(max_dim) < dim_size then
        Pointer.update(max_dim, dim_size);
      end if;
    end maxDimTraverse;

    function getDependentCref
      input output ComponentRef cref                "the cref to check";
      input Pointer<list<ComponentRef>> acc         "accumulator for relevant crefs";
      input UnorderedMap<ComponentRef, Integer> map "unordered map to check for relevance";
      input Boolean pseudo;
    algorithm
      // if causalized in pseudo array mode, the variables will only have subscript-free variables
      if pseudo then
        if UnorderedMap.contains(ComponentRef.stripSubscriptsExceptModel(cref), map) then
          Pointer.update(acc, cref :: Pointer.access(acc));
        end if;
      else
        if UnorderedMap.contains(cref, map) then
          Pointer.update(acc, cref :: Pointer.access(acc));
        end if;
      end if;
    end getDependentCref;

    function getDependentCrefIndices
      input list<ComponentRef> dependencies         "dependent var crefs";
      input UnorderedMap<ComponentRef, Integer> map "hash table to check for relevance";
      input Boolean negate = false;
      output list<Integer> indices = {};
    algorithm
      if negate then
        for cref in dependencies loop
          indices := -UnorderedMap.getSafe(cref, map) :: indices;
        end for;
      else
        for cref in dependencies loop
          indices := UnorderedMap.getSafe(cref, map) :: indices;
        end for;
      end if;
      // remove duplicates and sort
      indices := List.sort(List.unique(indices), intLt);
    end getDependentCrefIndices;

    function getDependentCrefIndicesPseudo
      input list<ComponentRef> dependencies         "dependent var crefs";
      input UnorderedMap<ComponentRef, Integer> map "hash table to check for relevance";
      input Mapping mapping                         "array <-> scalar index mapping";
      input Boolean negate = false;
      output list<Integer> indices = {};
    protected
      Integer var_arr_idx, var_start, var_scal_idx;
      list<Integer> sizes, subs;
    algorithm
      for cref in dependencies loop
        var_arr_idx := UnorderedMap.getSafe(ComponentRef.stripSubscriptsExceptModel(cref), map);
        (var_start, _) := mapping.var_AtS[var_arr_idx];
        sizes := list(Dimension.size(dim) for dim in Type.arrayDims(ComponentRef.nodeType(cref)));
        subs := list(Expression.integerValue(Subscript.toExp(sub)) for sub in ComponentRef.getSubscripts(cref));
        var_scal_idx := BackendUtil.frameToIndex(List.zip(sizes, subs), var_start);
        if negate then
          indices := -var_scal_idx :: indices;
        else
          indices := var_scal_idx :: indices;
        end if;
      end for;
      // remove duplicates and sort
      indices := List.sort(List.unique(indices), intLt);
    end getDependentCrefIndicesPseudo;

    function getDependentCrefIndicesPseudoFor
      input list<ComponentRef> dependencies                   "dependent var crefs";
      input UnorderedMap<ComponentRef, Integer> map           "hash table to check for relevance";
      input Mapping mapping                                   "array <-> scalar index mapping";
      input Iterator iter                                     "iterator frames";
      input Integer eqn_arr_idx;
      input Boolean negate = false;
      output array<list<Integer>> indices;
      output array<array<Integer>> mode_to_var;
    protected
      list<ComponentRef> names;
      list<Expression> ranges;
      Integer eqn_start, eqn_size, var_arr_idx, var_start, var_scal_idx, mode = 1;
      list<Integer> scal_lst;
      Integer idx;
      array<Integer> mode_to_var_row;
    algorithm
      (eqn_start, eqn_size) := mapping.eqn_AtS[eqn_arr_idx];
      indices := arrayCreate(eqn_size, {});
      mode_to_var := arrayCreate(eqn_size, arrayCreate(0,0));
      // create unique array for each equation
      for i in 1:eqn_size loop
        mode_to_var[i] := arrayCreate(listLength(dependencies),-1);
      end for;
      for cref in dependencies loop
        var_arr_idx := UnorderedMap.getSafe(ComponentRef.stripSubscriptsExceptModel(cref), map);
        (var_start, _) := mapping.var_AtS[var_arr_idx];
        (names, ranges) := Iterator.getFrames(iter);
        scal_lst := getScalarIndices(
          first   = var_start,
          sizes   = list(Dimension.size(dim) for dim in Type.arrayDims(ComponentRef.nodeType(cref))),
          subs    = list(Subscript.toExp(sub) for sub in ComponentRef.getSubscripts(cref)),
          frames  = List.zip(names, ranges)
        );

        if listLength(scal_lst) <> eqn_size then
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
            + " failed because number of flattened indices differ from equation size."});
          fail();
        end if;

        idx := 1;
        for var_scal_idx in listReverse(scal_lst) loop
          mode_to_var_row := mode_to_var[idx];
          mode_to_var_row[mode] := var_scal_idx;
          //print("mtv\n");
          //for mtvr in mode_to_var loop
            //for md in mtvr loop
              //print(intString(md));
            //end for;
            //print("\n");
          //end for;
          arrayUpdate(mode_to_var_row, mode, var_scal_idx);
          if negate then
            var_scal_idx := -var_scal_idx;
          end if;
          //print("scal: " + intString(var_scal_idx) + "\n");
          indices[idx] := var_scal_idx :: indices[idx];
          //print(toStringSingle(indices));
          idx := idx + 1;
        end for;
        mode := mode + 1;
      end for;

      // sort
      for i in 1:arrayLength(indices) loop
        indices[i] := List.sort(List.unique(indices[i]), intLt);
      end for;
    end getDependentCrefIndicesPseudoFor;

    function getScalarIndices
      input Integer first                                 "index of first variable. start counting from here";
      input list<Integer> sizes                           "list of variables sizes";
      input list<Expression> subs                         "list of cref subscripts";
      input list<tuple<ComponentRef, Expression>> frames  "list of frame tuples containing iterator name and range";
      output list<Integer> indices                        "list of scalarized indices";
    protected
      UnorderedMap<ComponentRef, Expression> replacements;
    algorithm
      replacements := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
      indices := combineFrames(first, sizes, subs, frames, replacements);
    end getScalarIndices;

    function combineFrames
      input Integer first;
      input list<Integer> sizes;
      input list<Expression> subs;
      input list<tuple<ComponentRef, Expression>> frames;
      input UnorderedMap<ComponentRef, Expression> replacements;
      input output list<Integer> indices = {};
    algorithm
      indices := match frames
        local
          list<tuple<ComponentRef, Expression>> rest;
          ComponentRef iterator;
          Expression start, step, stop, range;
          Option<Expression> step_opt;
          list<tuple<Integer, Integer>> ranges;

        // only occurs for scalar variables
        case {} then {first};

        // extract numeric information about the range
        case (iterator, Expression.RANGE(start=start, step=step_opt, stop=stop)) :: rest algorithm
          step := if Util.isSome(step_opt) then Util.getOption(step_opt) else Expression.INTEGER(1);
          // traverse every index in the range
          for index in Expression.integerValue(start):Expression.integerValue(step):Expression.integerValue(stop) loop
            UnorderedMap.add(iterator, Expression.INTEGER(index), replacements);
            if listEmpty(rest) then
              // bottom line, resolve current configuration and create index for it
              ranges  := resolveDimensionsSubscripts(sizes, subs, replacements);
              indices := BackendUtil.frameToIndex(ranges, first) :: indices;
            else
              // not last frame, go deeper
              indices := combineFrames(first, sizes, subs, rest, replacements, indices);
            end if;
          end for;
        then indices;

        case (iterator, range) :: _ algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because uniontype records are wrong: "
            + ComponentRef.toString(iterator) + " in " + Expression.toString(range)});
        then fail();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for an unknown reason."});
        then fail();

      end match;
    end combineFrames;

    function resolveDimensionsSubscripts
      input list<Integer> sizes;
      input list<Expression> subs;
      input UnorderedMap<ComponentRef, Expression> replacements;
      output list<tuple<Integer, Integer>> ranges;
    protected
      list<Expression> replaced;
      list<Integer> values;
    algorithm
      replaced := list(Expression.map(sub, function Replacements.applySimpleExp(replacements = replacements)) for sub in subs);
      values := list(Expression.integerValue(SimplifyExp.simplify(rep)) for rep in replaced);
      ranges := List.zip(sizes, values);
    end resolveDimensionsSubscripts;

  end Matrix;

  annotation(__OpenModelica_Interface="backend");
end NBAdjacency;

