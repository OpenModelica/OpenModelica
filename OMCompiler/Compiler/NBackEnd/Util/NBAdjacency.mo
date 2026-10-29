/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
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
  // OF imports
  import Absyn.Path;

  // Old Simcode imports
  import OldSimCode = SimCode;

  // NF imports
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import NFFunction.Function;
  import SimplifyExp = NFSimplifyExp;
  import Statement = NFStatement;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Operator = NFOperator;
  import NFOperator.Op;
  import Variable = NFVariable;

  // NB imports
  import Differentiate = NBDifferentiate;
  import NBDifferentiate.{DifferentiationArguments, DifferentiationType};
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationAttributes, EquationPointers, Iterator, IfEquationBody, WhenEquationBody, WhenStatement};
  import Solve = NBSolve;
  import BVariable = NBVariable;
  import NBVariable.{VariablePointers, VarData};
  import StrongComponent = NBStrongComponent;
  import Partition = NBPartition;

  // Util import
  import Array;
  import BackendUtil = NBBackendUtil;
  import BuiltinSystem = System;
  import BackendDAE = NBackendDAE;
  import NFInstNode.InstNode;
  import Slice = NBSlice;
  import StringUtil;
  import Vector;

public
  type MatrixStrictness  = enumeration(LINEAR, MATCHING, SORTING, FULL);

  function strictnessString
    input MatrixStrictness s;
    output String str;
  algorithm
    str := match s
      case MatrixStrictness.LINEAR    then "linear";
      case MatrixStrictness.MATCHING  then "matching";
      case MatrixStrictness.SORTING   then "sorting";
      case MatrixStrictness.FULL      then "full";
      else                                 "unknown";
    end match;
  end strictnessString;

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

    function empty
      output Mapping mapping = MAPPING(arrayCreate(0, 0), arrayCreate(0, 0),arrayCreate(0, (0,0)),arrayCreate(0, (0,0)));
    end empty;

    function create
      input EquationPointers eqns;
      input VariablePointers vars;
      output Mapping mapping;
    protected
      list<Pointer<Equation>> eqn_lst = EquationPointers.toList(eqns);
      list<Pointer<Variable>> var_lst = VariablePointers.toList(vars);
      array<Integer> eqn_StA, var_StA;
      array<tuple<Integer,Integer>> eqn_AtS, var_AtS;
      Integer eqn_scalar_size, var_scalar_size;
      Integer eqn_idx_scal = 1, eqn_idx_arr = 1, var_idx_scal = 1, var_idx_arr = 1;
    algorithm
      // prepare the mappings
      eqn_scalar_size := sum(Equation.size(eqn, true) for eqn in eqn_lst);
      var_scalar_size := sum(BVariable.size(var, true) for var in var_lst);
      eqn_StA := arrayCreate(eqn_scalar_size, -1);
      var_StA := arrayCreate(var_scalar_size, -1);
      eqn_AtS := arrayCreate(EquationPointers.size(eqns), (-1, -1));
      var_AtS := arrayCreate(VariablePointers.size(vars), (-1, -1));

      // fill the arrays
      (eqn_StA, var_StA, eqn_AtS, var_AtS) := fill_(eqn_StA, var_StA, eqn_AtS, var_AtS, eqn_lst, var_lst, eqn_idx_scal, eqn_idx_arr, var_idx_scal, var_idx_arr);

      // compile mapping
      mapping := MAPPING(eqn_StA, var_StA, eqn_AtS, var_AtS);
    end create;

    function expand
      input output Mapping mapping;
      input list<Pointer<Equation>> eqn_lst;
      input list<Pointer<Variable>> var_lst;
    protected
      array<Integer> eqn_StA, var_StA;
      array<tuple<Integer,Integer>> eqn_AtS, var_AtS;
      Integer eqn_scalar_size, var_scalar_size;
      Integer neqn_scal = sum(Equation.size(eqn, true) for eqn in eqn_lst);
      Integer nvar_scal = sum(BVariable.size(var, true) for var in var_lst);
      Integer neqn_arr = listLength(eqn_lst);
      Integer nvar_arr = listLength(var_lst);
      Integer eqn_idx_scal = arrayLength(mapping.eqn_StA) + 1, eqn_idx_arr = arrayLength(mapping.eqn_AtS) + 1;
      Integer var_idx_scal = arrayLength(mapping.var_StA) + 1, var_idx_arr = arrayLength(mapping.var_AtS) + 1;
    algorithm

      // copy all data
      eqn_StA := Array.expandToSize(eqn_idx_scal - 1 + neqn_scal, mapping.eqn_StA, -1);
      var_StA := Array.expandToSize(var_idx_scal - 1 + nvar_scal, mapping.var_StA, -1);
      eqn_AtS := Array.expandToSize(eqn_idx_arr - 1 + neqn_arr, mapping.eqn_AtS, (-1, -1));
      var_AtS := Array.expandToSize(var_idx_arr - 1 + nvar_arr, mapping.var_AtS, (-1, -1));

      // fill the new sections
      (eqn_StA, var_StA, eqn_AtS, var_AtS) := fill_(eqn_StA, var_StA, eqn_AtS, var_AtS, eqn_lst, var_lst, eqn_idx_scal, eqn_idx_arr, var_idx_scal, var_idx_arr);

      // compile mapping
      mapping := MAPPING(eqn_StA, var_StA, eqn_AtS, var_AtS);
    end expand;

    function getEqnScalIndices
      input Integer arr_idx;
      input Mapping mapping;
      input Boolean reverse = false;
      output list<Integer> scal_indices;
    protected
      Integer start, length;
    algorithm
      (start, length) := mapping.eqn_AtS[arr_idx];
      scal_indices := if reverse then
        List.intRange2(start + length - 1, start) else
        List.intRange2(start, start + length - 1);
    end getEqnScalIndices;

    function getVarScalIndices
      input Integer arr_idx;
      input Mapping mapping;
      input list<Subscript> subs;
      input list<Dimension> dims;
      input Boolean reverse = false;
      output list<Integer> scal_indices;
    protected
      Integer start, length;
      function subscriptedIndices
        input Integer start;
        input Integer length;
        input list<Integer> slice;
        output list<Integer> scal_indices;
      algorithm
        scal_indices := List.intRange2(start, start + length - 1);
        if not listEmpty(slice) then
          scal_indices := List.keepPositions(scal_indices, slice);
        end if;
      end subscriptedIndices;
    algorithm
      (start, length) := mapping.var_AtS[arr_idx];

      scal_indices := match subs
        local
          Subscript sub;
          list<list<Subscript>> subs_lst;
          list<Integer> slice = {}, dim_sizes, values;

        // no subscripts -> create full index list
        case {} then subscriptedIndices(start, length, {});

        // all subscripts are whole -> create full index list
        case _ guard(List.all(subs, Subscript.isWhole)) then subscriptedIndices(start, length, {});

        // only one subscript -> apply simple rule
        case {sub} algorithm
          slice := Subscript.toIndexList(sub, length);
        then subscriptedIndices(start, length, slice);

        // multiple subscripts -> apply location to index mapping rules
        case _ algorithm
          subs_lst  := Subscript.scalarizeList(subs, dims, true);
          subs_lst  := List.combination(subs_lst);
          dim_sizes := list(Dimension.size(dim) for dim in dims);
          for sub_lst in listReverse(subs_lst) loop
            values  := list(Subscript.toInteger(s) for s in sub_lst);
            slice   := Slice.locationToIndex(dim_sizes, values, start) :: slice;
          end for;
        then slice;

        else fail();
      end match;

      if reverse then
        scal_indices := listReverse(scal_indices);
      end if;
    end getVarScalIndices;

  protected
    function fill_
      input output array<Integer> eqn_StA;
      input output array<Integer> var_StA;
      input output array<tuple<Integer,Integer>> eqn_AtS;
      input output array<tuple<Integer,Integer>> var_AtS;
      input list<Pointer<Equation>> eqn_lst;
      input list<Pointer<Variable>> var_lst;
      input Integer eqn_idx_scal_start;
      input Integer eqn_idx_arr_start;
      input Integer var_idx_scal_start;
      input Integer var_idx_arr_start;
    protected
      Integer size;
      Integer eqn_idx_scal = eqn_idx_scal_start;
      Integer eqn_idx_arr = eqn_idx_arr_start;
      Integer var_idx_scal = var_idx_scal_start;
      Integer var_idx_arr= var_idx_arr_start;
    algorithm
      // fill equation mapping
      for eqn_ptr in eqn_lst loop
        size := Equation.size(eqn_ptr, true);
        eqn_AtS[eqn_idx_arr] := (eqn_idx_scal, size);
        for i in eqn_idx_scal:eqn_idx_scal+size-1 loop
          eqn_StA[i] := eqn_idx_arr;
        end for;
        eqn_idx_scal := eqn_idx_scal + size;
        eqn_idx_arr := eqn_idx_arr + 1;
      end for;
      // fill variable mapping
      for var_ptr in var_lst loop
        size := BVariable.size(var_ptr, true);
        var_AtS[var_idx_arr] := (var_idx_scal, size);
        for i in var_idx_scal:var_idx_scal+size-1 loop
          var_StA[i] := var_idx_arr;
        end for;
        var_idx_scal := var_idx_scal + size;
        var_idx_arr := var_idx_arr + 1;
      end for;
    end fill_;
  end Mapping;

  uniontype Mode
    record MODE
      "most of the time this will only have one cref. if there are multiple crefs
      representing the same variable its a multi mode and the equation needs to
      be split when solved for it"
      ComponentRef eqn_name     "the equation name";
      list<ComponentRef> crefs  "the cref(s) to solve for";
      Boolean scalarize         "true if the equation needs to be scalarized to find the cref to solve for";
    end MODE;

    function toString
      input Mode mode;
      output String str = "[eqn: " + ComponentRef.toString(mode.eqn_name) + ", crefs: " + List.toString(mode.crefs, ComponentRef.toString) + ", scal: " + boolString(mode.scalarize) + "]";
    end toString;

    function hash
      input Mode mode;
      output Integer hash = ComponentRef.hash(mode.eqn_name);
    end hash;

    function isEqual
      input Mode mode1;
      input Mode mode2;
      output Boolean b = ComponentRef.isEqual(mode1.eqn_name, mode2.eqn_name) and mode1.scalarize == mode2.scalarize
        and List.isEqualOnTrue(mode1.crefs, mode2.crefs, ComponentRef.isEqual);
    end isEqual;

    function create
      input ComponentRef eqn_name;
      input list<ComponentRef> crefs;
      input Boolean scalarize;
      output Mode mode = MODE(eqn_name, list(ComponentRef.simplifySubscripts(cref) for cref in crefs), scalarize);
    end create;

    function merge
      input Mode mode1;
      input Mode mode2;
      output Mode oMode = MODE(mode1.eqn_name, listAppend(mode1.crefs, mode2.crefs), mode1.scalarize or mode2.scalarize);
    end merge;

  end Mode;

  type ModeTable = Vector<Mode>
    "the distinct causalization modes. a matrix entry refers to one by its index
    in here (0 for none), kept in the matrix payload instead of in a map keyed
    on the (equation, variable) pair.";

  package Modes
    function new
      output ModeTable modes = Vector.new<Mode>(0);
    end new;

    function add
      input ModeTable modes;
      input Mode mode;
      output Integer id;
    algorithm
      Vector.push(modes, mode);
      id := Vector.size(modes);
    end add;

    function get
      "the mode of the (eqn, var) entry. duplicate entries are merged the way
      UnorderedMap.addMerge did, newest first, which is the row order."
      input ModeTable modes;
      input IntMatrix m;
      input array<Integer> data;
      input array<Integer> ids;
      input Integer eqn;
      input Integer var;
      output Option<Mode> res = NONE();
    protected
      array<Integer> pstart = IntMatrix.pieceStarts(m);
      array<Integer> plen = IntMatrix.pieceLengths(m);
      Mode mode;
    algorithm
      for p in m.first[eqn]:m.first[eqn] + m.pieces[eqn] - 1 loop
        for k in pstart[p]:pstart[p] + plen[p] - 1 loop
          if data[k] == var and ids[k] > 0 then
            mode := Vector.getNoBounds(modes, ids[k]);
            res := match res
              local Mode acc;
              case SOME(acc) then SOME(Mode.merge(acc, mode));
              else SOME(mode);
            end match;
          end if;
        end for;
      end for;
    end get;
  end Modes;

  uniontype IntMatrix
    "Adjacency rows stored flat in one append-only integer buffer. A row is a
    list of pieces, every piece is a range of the buffer. Rows can share
    sections: pieces of different rows that point to the same range (e.g. all
    rows of an algorithm depend on the same variables, which are stored once).
    Nothing in here is a pointer, so the collector does not have to walk the
    nonzeros. aux carries one extra integer per entry (the causalization mode id
    of the normal matrix), and is empty where it is not used.

    The entries of a row are numbered 1 .. rowLength(m, row) over its pieces in
    order (position), see get/dataIndex."

    record INT_MATRIX
      array<Integer> first    "row -> index of its first piece";
      array<Integer> pieces   "row -> number of pieces";
      Vector<Integer> pstart  "piece -> 1-based index of its first entry in data";
      Vector<Integer> plen    "piece -> number of entries";
      Vector<Integer> data    "entry buffer, only appended to";
      Vector<Integer> aux     "payload parallel to data, empty if unused";
    end INT_MATRIX;

    uniontype Builder
      "The matrix is filled by collecting (row, entry) pairs in any order and
      references from rows to sections that are stored once; fromBuilder() then
      groups them by row in one counting sort. Every row gets its own entries as
      first piece, followed by its sections, the latest added first."
      record BUILDER
        Vector<Integer> pairs     "(row, entry) pairs";
        Vector<Integer> aux       "payload of the pairs";
        Boolean hasAux;
        Vector<Integer> refs      "(row, section) pairs";
        Vector<Integer> sec_start "section -> 1-based index of its first entry in sec_data";
        Vector<Integer> sec_len   "section -> number of entries";
        Vector<Integer> sec_data  "entries of all sections";
        Vector<Integer> sec_aux   "payload of the section entries";
      end BUILDER;
    end Builder;

    uniontype CopyMap
      "the ranges of one matrix already copied into another one, so that rows
      that share a section in the source share it in the target as well"
      record COPY_MAP
        array<Integer> target "source range start -> target range start, 0 if not copied";
        array<Integer> length "source range start -> length of the copied range";
      end COPY_MAP;
    end CopyMap;

    function new
      input Integer rows;
      output IntMatrix m = INT_MATRIX(arrayCreate(rows, 1), arrayCreate(rows, 0),
        Vector.new<Integer>(0), Vector.new<Integer>(0), Vector.new<Integer>(0), Vector.new<Integer>(0));
    end new;

    function rows
      input IntMatrix m;
      output Integer n = arrayLength(m.first);
    end rows;

    function rowLength
      "number of entries of the row over all its pieces"
      input IntMatrix m;
      input Integer row;
      output Integer n = 0;
    protected
      array<Integer> plen = Vector.rawArray(m.plen);
    algorithm
      for p in m.first[row]:m.first[row] + m.pieces[row] - 1 loop
        n := n + plen[p];
      end for;
    end rowLength;

    function nonZeroCount
      "number of entries, shared sections counted once per row"
      input IntMatrix m;
      output Integer count = 0;
    protected
      array<Integer> plen = Vector.rawArray(m.plen);
    algorithm
      for r in 1:arrayLength(m.first) loop
        for p in m.first[r]:m.first[r] + m.pieces[r] - 1 loop
          count := count + plen[p];
        end for;
      end for;
    end nonZeroCount;

    function storedCount
      "number of entries actually stored, shared sections counted once"
      input IntMatrix m;
      output Integer count = Vector.size(m.data);
    end storedCount;

    function pieceCount
      input IntMatrix m;
      output Integer count = Vector.size(m.pstart);
    end pieceCount;

    function entries
      "the raw entry buffer, indexed by the pieces (see pieceStarts/pieceLengths).
      invalidated by anything that adds entries"
      input IntMatrix m;
      output array<Integer> data = Vector.rawArray(m.data);
    end entries;

    function payload
      input IntMatrix m;
      output array<Integer> aux = Vector.rawArray(m.aux);
    end payload;

    function pieceStarts
      "piece -> first entry in the raw entry buffer. invalidated by anything
      that adds pieces"
      input IntMatrix m;
      output array<Integer> pstart = Vector.rawArray(m.pstart);
    end pieceStarts;

    function pieceLengths
      input IntMatrix m;
      output array<Integer> plen = Vector.rawArray(m.plen);
    end pieceLengths;

    function pieceBegin
      "index of the first entry of the piece in the entry buffer"
      input IntMatrix m;
      input Integer piece;
      output Integer k = Vector.getNoBounds(m.pstart, piece);
    end pieceBegin;

    function pieceEnd
      "index of the last entry of the piece in the entry buffer"
      input IntMatrix m;
      input Integer piece;
      output Integer k = Vector.getNoBounds(m.pstart, piece) + Vector.getNoBounds(m.plen, piece) - 1;
    end pieceEnd;

    function dataIndex
      "the index in the entry buffer of the entry at position pos (1-based) of
      the row, -1 if the row has less entries"
      input IntMatrix m;
      input Integer row;
      input Integer pos;
      output Integer index = -1;
    protected
      array<Integer> pstart = Vector.rawArray(m.pstart);
      array<Integer> plen = Vector.rawArray(m.plen);
      Integer k = pos;
    algorithm
      for p in m.first[row]:m.first[row] + m.pieces[row] - 1 loop
        if k <= plen[p] then
          index := pstart[p] + k - 1;
          break;
        end if;
        k := k - plen[p];
      end for;
    end dataIndex;

    function get
      "the entry at position pos (1-based) of the row"
      input IntMatrix m;
      input Integer row;
      input Integer pos;
      output Integer value = Vector.getNoBounds(m.data, dataIndex(m, row, pos));
    end get;

    function rowContains
      "the row has the entry value"
      input IntMatrix m;
      input Integer row;
      input Integer value;
      output Boolean b = false;
    protected
      array<Integer> data = Vector.rawArray(m.data);
      array<Integer> pstart = Vector.rawArray(m.pstart);
      array<Integer> plen = Vector.rawArray(m.plen);
    algorithm
      for p in m.first[row]:m.first[row] + m.pieces[row] - 1 loop
        for k in pstart[p]:pstart[p] + plen[p] - 1 loop
          if data[k] == value then
            b := true;
            return;
          end if;
        end for;
      end for;
    end rowContains;

    function toList
      input IntMatrix m;
      input Integer row;
      output list<Integer> lst = {};
    protected
      array<Integer> data = Vector.rawArray(m.data);
      array<Integer> pstart = Vector.rawArray(m.pstart);
      array<Integer> plen = Vector.rawArray(m.plen);
    algorithm
      for p in m.first[row] + m.pieces[row] - 1:-1:m.first[row] loop
        for k in pstart[p] + plen[p] - 1:-1:pstart[p] loop
          lst := data[k] :: lst;
        end for;
      end for;
    end toList;

    function setRow
      "replaces a row by appending its new entries to the buffer. the payload,
      if any, is not maintained"
      input IntMatrix m;
      input Integer row;
      input list<Integer> values;
    protected
      Integer n = listLength(values);
    algorithm
      if n > 0 then
        addPiece(m, row, Vector.size(m.data) + 1, n);
        for v in values loop
          Vector.push(m.data, v);
        end for;
      else
        arrayUpdate(m.pieces, row, 0);
      end if;
    end setRow;

    function setRowFromArray
      "setRow with the first n entries of values"
      input IntMatrix m;
      input Integer row;
      input array<Integer> values;
      input Integer n;
    algorithm
      if n > 0 then
        addPiece(m, row, Vector.size(m.data) + 1, n);
        for i in 1:n loop
          Vector.push(m.data, values[i]);
        end for;
      else
        arrayUpdate(m.pieces, row, 0);
      end if;
    end setRowFromArray;

    function reserveData
      "makes room for extra more entries so that adding them does not grow the buffer"
      input IntMatrix m;
      input Integer extra;
      input Boolean withAux = false;
    algorithm
      Vector.reserve(m.data, Vector.size(m.data) + extra);
      if withAux then
        Vector.reserve(m.aux, Vector.size(m.aux) + extra);
      end if;
    end reserveData;

    function clearRow
      input IntMatrix m;
      input Integer row;
    algorithm
      arrayUpdate(m.pieces, row, 0);
    end clearRow;

    function newCopyMap
      "a copy map for copying rows out of from"
      input IntMatrix from;
      output CopyMap map = COPY_MAP(arrayCreate(Vector.size(from.data) + 1, 0), arrayCreate(Vector.size(from.data) + 1, 0));
    end newCopyMap;

    function copyRow
      "appends row src of `from` (whose buffer must be given) as row dst of m.
      Ranges that were copied before with the same map are shared, not copied again."
      input IntMatrix from;
      input Integer src;
      input array<Integer> from_data;
      input array<Integer> from_aux;
      input IntMatrix m;
      input Integer dst;
      input CopyMap map;
    protected
      array<Integer> pstart = Vector.rawArray(from.pstart);
      array<Integer> plen = Vector.rawArray(from.plen);
      Boolean aux = arrayLength(from_aux) > 0;
      Integer ps, pl, target, n = 0;
    algorithm
      arrayUpdate(m.first, dst, Vector.size(m.pstart) + 1);
      for p in from.first[src]:from.first[src] + from.pieces[src] - 1 loop
        ps := pstart[p];
        pl := plen[p];
        if pl > 0 then
          if map.target[ps] > 0 and map.length[ps] == pl then
            target := map.target[ps];
          else
            target := Vector.size(m.data) + 1;
            for k in ps:ps + pl - 1 loop
              Vector.push(m.data, from_data[k]);
              if aux then
                Vector.push(m.aux, from_aux[k]);
              end if;
            end for;
            if map.target[ps] == 0 then
              arrayUpdate(map.target, ps, target);
              arrayUpdate(map.length, ps, pl);
            end if;
          end if;
          Vector.push(m.pstart, target);
          Vector.push(m.plen, pl);
          n := n + 1;
        end if;
      end for;
      arrayUpdate(m.pieces, dst, n);
    end copyRow;

    function expandRows
      input output IntMatrix m;
      input Integer shift;
    algorithm
      if shift > 0 then
        m := INT_MATRIX(Array.expandToSize(arrayLength(m.first) + shift, m.first, 1),
                        Array.expandToSize(arrayLength(m.pieces) + shift, m.pieces, 0),
                        m.pstart, m.plen, m.data, m.aux);
      end if;
    end expandRows;

    function transpose
      "transposes the matrix, dropping any payload. a negative entry -v means
      that row occurs negated in column v. the own entries of each result row come
      out descending, matching what List.sort(.., intLt) produced before.
      A section shared by the rows R becomes a section R shared by the result
      rows of its entries (-R for its negated entries), so sharing survives.
      slack reserves buffer space for rows that are merged in afterwards."
      input IntMatrix m;
      input Integer size "number of rows of the result (does not have to be square!)";
      input Integer slack = 0;
      output IntMatrix mT;
    protected
      array<Integer> data = Vector.rawArray(m.data);
      array<Integer> pstart = Vector.rawArray(m.pstart);
      array<Integer> plen = Vector.rawArray(m.plen);
      Integer n = arrayLength(m.first), stored = Vector.size(m.data);
      // shared ranges: length of the first piece seen at a start, and how many rows use it
      array<Integer> key_len = arrayCreate(stored + 1, -1);
      array<Integer> key_cnt = arrayCreate(stored + 1, 0);
      array<list<Integer>> key_rows;
      array<Integer> start, len, own_start, out, tfirst, tpieces, tps, tpl, sec_pos, sec_neg;
      list<Integer> shared = {};
      Integer nnz = 0, idx, pos, ps, pl, total, npieces = 0, sec_total = 0, r2, cur;
      Boolean negated = false;
    algorithm
      // 1. find the ranges shared by more than one row
      for r in 1:n loop
        for p in m.first[r]:m.first[r] + m.pieces[r] - 1 loop
          ps := pstart[p];
          pl := plen[p];
          if pl > 0 then
            if key_len[ps] == -1 then
              arrayUpdate(key_len, ps, pl);
            end if;
            if key_len[ps] == pl then
              arrayUpdate(key_cnt, ps, key_cnt[ps] + 1);
              if key_cnt[ps] == 2 then
                shared := ps :: shared;
              end if;
            end if;
          end if;
        end for;
      end for;
      shared := List.sort(shared, intGt);

      // 2. count the own entries per result row
      start := arrayCreate(size, 1);
      len   := arrayCreate(size, 0);
      for r in 1:n loop
        for p in m.first[r]:m.first[r] + m.pieces[r] - 1 loop
          if not isShared(pstart[p], plen[p], key_len, key_cnt) then
            for k in pstart[p]:pstart[p] + plen[p] - 1 loop
              idx := intAbs(data[k]);
              if idx > 0 and idx <= size then
                arrayUpdate(len, idx, len[idx] + 1);
                nnz := nnz + 1;
                negated := negated or data[k] < 0;
              else
                Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for variable index " + intString(data[k]) + ".
                  The variables have to be dense (without empty spaces) for this to work!"});
              end if;
            end for;
          end if;
        end for;
      end for;

      // 3. the rows of every shared range and the number of result pieces
      key_rows := arrayCreate(if listEmpty(shared) then 0 else stored + 1, {});
      if not listEmpty(shared) then
        for r in n:-1:1 loop
          for p in m.first[r]:m.first[r] + m.pieces[r] - 1 loop
            if isShared(pstart[p], plen[p], key_len, key_cnt) then
              arrayUpdate(key_rows, pstart[p], r :: key_rows[pstart[p]]);
            end if;
          end for;
        end for;
      end if;
      tpieces := arrayCreate(size, 0);
      for c in 1:size loop
        if len[c] > 0 then
          arrayUpdate(tpieces, c, 1);
        end if;
      end for;
      sec_pos := arrayCreate(if listEmpty(shared) then 0 else stored + 1, 0);
      sec_neg := arrayCreate(if listEmpty(shared) then 0 else stored + 1, 0);
      for s in shared loop
        for k in s:s + key_len[s] - 1 loop
          idx := intAbs(data[k]);
          if idx > 0 and idx <= size then
            arrayUpdate(tpieces, idx, tpieces[idx] + 1);
            if data[k] > 0 then
              arrayUpdate(sec_pos, s, 1);
            else
              arrayUpdate(sec_neg, s, 1);
            end if;
          else
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for variable index " + intString(data[k]) + ".
              The variables have to be dense (without empty spaces) for this to work!"});
          end if;
        end for;
        sec_total := sec_total + (sec_pos[s] + sec_neg[s]) * listLength(key_rows[s]);
      end for;

      // 4. scatter the own entries, using start as the cursor and winding it back afterwards
      pos := 1;
      for c in 1:size loop
        arrayUpdate(start, c, pos);
        pos := pos + len[c];
      end for;
      total := nnz + sec_total;
      out := arrayCreate(total + slack, 0);
      // positive entries first, rows descending
      for r in n:-1:1 loop
        for p in m.first[r]:m.first[r] + m.pieces[r] - 1 loop
          if not isShared(pstart[p], plen[p], key_len, key_cnt) then
            for k in pstart[p]:pstart[p] + plen[p] - 1 loop
              idx := data[k];
              if idx > 0 and idx <= size then
                arrayUpdate(out, start[idx], r);
                arrayUpdate(start, idx, start[idx] + 1);
              end if;
            end for;
          end if;
        end for;
      end for;
      // then the negated ones, rows ascending so that -row descends
      if negated then
        for r in 1:n loop
          for p in m.first[r]:m.first[r] + m.pieces[r] - 1 loop
            if not isShared(pstart[p], plen[p], key_len, key_cnt) then
              for k in pstart[p]:pstart[p] + plen[p] - 1 loop
                idx := data[k];
                if idx < 0 and -idx <= size then
                  arrayUpdate(out, start[-idx], -r);
                  arrayUpdate(start, -idx, start[-idx] + 1);
                end if;
              end for;
            end if;
          end for;
        end for;
      end if;
      for c in 1:size loop
        arrayUpdate(start, c, start[c] - len[c]);
      end for;

      // 5. the transposed sections: rows descending, negated rows ascending so that -row descends
      cur := nnz + 1;
      for s in shared loop
        if sec_pos[s] > 0 then
          arrayUpdate(sec_pos, s, cur);
          for r in listReverse(key_rows[s]) loop
            arrayUpdate(out, cur, r);
            cur := cur + 1;
          end for;
        end if;
        if sec_neg[s] > 0 then
          arrayUpdate(sec_neg, s, cur);
          for r in key_rows[s] loop
            arrayUpdate(out, cur, -r);
            cur := cur + 1;
          end for;
        end if;
      end for;

      // 6. the pieces: own entries first, then the sections in order of their start
      tfirst := arrayCreate(size, 1);
      for c in 1:size loop
        arrayUpdate(tfirst, c, npieces + 1);
        npieces := npieces + tpieces[c];
      end for;
      tps := arrayCreate(npieces, 0);
      tpl := arrayCreate(npieces, 0);
      for c in 1:size loop
        arrayUpdate(tpieces, c, 0);
        if len[c] > 0 then
          arrayUpdate(tps, tfirst[c], start[c]);
          arrayUpdate(tpl, tfirst[c], len[c]);
          arrayUpdate(tpieces, c, 1);
        end if;
      end for;
      for s in shared loop
        r2 := listLength(key_rows[s]);
        for k in s:s + key_len[s] - 1 loop
          idx := intAbs(data[k]);
          if idx > 0 and idx <= size then
            pos := tfirst[idx] + tpieces[idx];
            arrayUpdate(tps, pos, if data[k] > 0 then sec_pos[s] else sec_neg[s]);
            arrayUpdate(tpl, pos, r2);
            arrayUpdate(tpieces, idx, tpieces[idx] + 1);
          end if;
        end for;
      end for;

      mT := INT_MATRIX(tfirst, tpieces, Vector.fromArrayNoCopy(tps, npieces), Vector.fromArrayNoCopy(tpl, npieces),
                       Vector.fromArrayNoCopy(out, total), Vector.new<Integer>(0));
    end transpose;

    function newBuilder
      input Integer capacity = 0;
      input Boolean withAux = false;
      output Builder b = Builder.BUILDER(Vector.new<Integer>(2 * capacity),
                                         Vector.new<Integer>(if withAux then capacity else 0), withAux,
                                         Vector.new<Integer>(0), Vector.new<Integer>(0), Vector.new<Integer>(0),
                                         Vector.new<Integer>(0), Vector.new<Integer>(0));
    end newBuilder;

    function builderAdd
      input Builder b;
      input Integer row;
      input Integer value;
    algorithm
      Vector.push(b.pairs, row);
      Vector.push(b.pairs, value);
    end builderAdd;

    function builderAddAux
      input Builder b;
      input Integer row;
      input Integer value;
      input Integer aux;
    algorithm
      Vector.push(b.pairs, row);
      Vector.push(b.pairs, value);
      Vector.push(b.aux, aux);
    end builderAddAux;

    function builderAddList
      "adds a whole row front, keeping the order of the list"
      input Builder b;
      input Integer row;
      input list<Integer> values;
      input Integer aux = 0;
    algorithm
      for v in listReverse(values) loop
        Vector.push(b.pairs, row);
        Vector.push(b.pairs, v);
        if b.hasAux then
          Vector.push(b.aux, aux);
        end if;
      end for;
    end builderAddList;

    function builderSection
      "stores a section once, rows refer to it with builderAddSection"
      input Builder b;
      input list<Integer> values;
      input Integer aux = 0;
      output Integer section;
    algorithm
      Vector.push(b.sec_start, Vector.size(b.sec_data) + 1);
      Vector.push(b.sec_len, listLength(values));
      for v in values loop
        Vector.push(b.sec_data, v);
        if b.hasAux then
          Vector.push(b.sec_aux, aux);
        end if;
      end for;
      section := Vector.size(b.sec_start);
    end builderSection;

    function builderAddSection
      "adds the section to the row"
      input Builder b;
      input Integer row;
      input Integer section;
    algorithm
      Vector.push(b.refs, row);
      Vector.push(b.refs, section);
    end builderAddSection;

    function builderAddRowOf
      "adds the pieces of row src of m to row dst as sections, ranges that were
      added before (see seen, indexed by the start of the range) are shared"
      input Builder b;
      input Integer dst;
      input IntMatrix m;
      input Integer src;
      input array<Integer> seen "range start -> section, 0 if not added";
    protected
      array<Integer> data = Vector.rawArray(m.data);
      array<Integer> aux = Vector.rawArray(m.aux);
      array<Integer> pstart = Vector.rawArray(m.pstart);
      array<Integer> plen = Vector.rawArray(m.plen);
      Boolean has_aux = arrayLength(aux) > 0;
      Integer ps, pl, sec;
    algorithm
      // latest added first: add the pieces back to front
      for p in m.first[src] + m.pieces[src] - 1:-1:m.first[src] loop
        ps := pstart[p];
        pl := plen[p];
        if pl > 0 then
          sec := seen[ps];
          if sec == 0 or Vector.getNoBounds(b.sec_len, sec) <> pl then
            Vector.push(b.sec_start, Vector.size(b.sec_data) + 1);
            Vector.push(b.sec_len, pl);
            for k in ps:ps + pl - 1 loop
              Vector.push(b.sec_data, data[k]);
              if b.hasAux then
                Vector.push(b.sec_aux, if has_aux then aux[k] else 0);
              end if;
            end for;
            sec := Vector.size(b.sec_start);
            if seen[ps] == 0 then
              arrayUpdate(seen, ps, sec);
            end if;
          end if;
          builderAddSection(b, dst, sec);
        end if;
      end for;
    end builderAddRowOf;

    function toBuilder
      "seeds a builder with the rows of an existing matrix as sections, so that
      fromBuilder puts them back in the same order and keeps shared sections shared"
      input IntMatrix m;
      input Integer capacity = 0;
      input Boolean withAux = false;
      output Builder b;
    protected
      array<Integer> seen = arrayCreate(Vector.size(m.data) + 1, 0);
    algorithm
      b := newBuilder(capacity, withAux);
      for r in 1:arrayLength(m.first) loop
        builderAddRowOf(b, r, m, r, seen);
      end for;
    end toBuilder;

    function fromBuilder
      "groups the collected pairs by row. entries were prepended to their row
      before, so the pairs are distributed back to front. The own entries of a
      row are its first piece, its sections follow, the latest added first."
      input Builder b;
      input Integer rows;
      output IntMatrix m;
    protected
      array<Integer> raw = Vector.rawArray(b.pairs);
      array<Integer> raux = Vector.rawArray(b.aux);
      array<Integer> refs = Vector.rawArray(b.refs);
      array<Integer> sec_start = Vector.rawArray(b.sec_start);
      array<Integer> sec_len = Vector.rawArray(b.sec_len);
      array<Integer> sec_data = Vector.rawArray(b.sec_data);
      array<Integer> sec_aux = Vector.rawArray(b.sec_aux);
      array<Integer> start, len, out, aout, first, pieces, ps, pl;
      Integer n = intDiv(Vector.size(b.pairs), 2), nref = intDiv(Vector.size(b.refs), 2);
      Integer nsec = Vector.size(b.sec_data), r, pos = 1, p, npieces = 0;
    algorithm
      start  := arrayCreate(rows, 1);
      len    := arrayCreate(rows, 0);
      pieces := arrayCreate(rows, 0);

      for i in 1:n loop
        r := raw[2*i - 1];
        arrayUpdate(len, r, len[r] + 1);
      end for;

      for i in 1:rows loop
        arrayUpdate(start, i, pos);
        pos := pos + len[i];
      end for;

      // own entries, then the sections behind them
      out  := arrayCreate(n + nsec, 0);
      aout := arrayCreate(if b.hasAux then n + nsec else 0, 0);

      // scatter, using start as the cursor and winding it back afterwards
      for i in n:-1:1 loop
        r := raw[2*i - 1];
        p := start[r];
        arrayUpdate(out, p, raw[2*i]);
        if b.hasAux then
          arrayUpdate(aout, p, raux[i]);
        end if;
        arrayUpdate(start, r, p + 1);
      end for;

      for i in 1:rows loop
        arrayUpdate(start, i, start[i] - len[i]);
      end for;

      for k in 1:nsec loop
        arrayUpdate(out, n + k, sec_data[k]);
        if b.hasAux then
          arrayUpdate(aout, n + k, sec_aux[k]);
        end if;
      end for;

      // pieces: the own entries, then the sections, the latest added first
      for i in 1:rows loop
        if len[i] > 0 then
          arrayUpdate(pieces, i, 1);
        end if;
      end for;
      for i in 1:nref loop
        r := refs[2*i - 1];
        arrayUpdate(pieces, r, pieces[r] + 1);
      end for;
      first := arrayCreate(rows, 1);
      for i in 1:rows loop
        arrayUpdate(first, i, npieces + 1);
        npieces := npieces + pieces[i];
      end for;
      ps := arrayCreate(npieces, 0);
      pl := arrayCreate(npieces, 0);
      for i in 1:rows loop
        arrayUpdate(pieces, i, 0);
        if len[i] > 0 then
          arrayUpdate(ps, first[i], start[i]);
          arrayUpdate(pl, first[i], len[i]);
          arrayUpdate(pieces, i, 1);
        end if;
      end for;
      for i in nref:-1:1 loop
        r := refs[2*i - 1];
        p := first[r] + pieces[r];
        arrayUpdate(ps, p, n + sec_start[refs[2*i]]);
        arrayUpdate(pl, p, sec_len[refs[2*i]]);
        arrayUpdate(pieces, r, pieces[r] + 1);
      end for;

      m := INT_MATRIX(first, pieces, Vector.fromArrayNoCopy(ps, npieces), Vector.fromArrayNoCopy(pl, npieces),
                      Vector.fromArrayNoCopy(out, n + nsec), Vector.fromArrayNoCopy(aout, arrayLength(aout)));
    end fromBuilder;

    function toString
      input IntMatrix m;
      output String str = "";
    protected
      Integer skip = stringLength(intString(arrayLength(m.first))) + 1;
      String tmp;
    algorithm
      for row in 1:arrayLength(m.first) loop
        tmp := intString(row);
        str := str + "\t(" + tmp + ")" + StringUtil.repeat(" ", skip - stringLength(tmp)) + List.toString(toList(m, row), intString) + "\n";
      end for;
    end toString;

  protected
    function addPiece
      "appends a piece to the pieces buffer and makes it the only piece of the row"
      input IntMatrix m;
      input Integer row;
      input Integer ps;
      input Integer pl;
    algorithm
      arrayUpdate(m.first, row, Vector.size(m.pstart) + 1);
      arrayUpdate(m.pieces, row, 1);
      Vector.push(m.pstart, ps);
      Vector.push(m.plen, pl);
    end addPiece;

    function isShared
      input Integer ps;
      input Integer pl;
      input array<Integer> key_len;
      input array<Integer> key_cnt;
      output Boolean b = pl > 0 and key_len[ps] == pl and key_cnt[ps] > 1;
    end isShared;
  end IntMatrix;

  uniontype Matrix
    "used to store adjacency information for the bipartite graph representing the system of equations and variables
    you have to create it in this specific order: EMPTY->FULL->FINAL(LINEAR)->FINAL->(MATCHING)->FINAL(SORTING)
    and store the FULL for further use."

    record EMPTY "placeholder for empty matrices, just stores intended strictness"
      MatrixStrictness st;
    end EMPTY;

    record FULL "contains all information needed. create specific final matrices from this"
      array<ComponentRef> equation_names;
      array<UnorderedSet<ComponentRef>> occurrences;
      array<UnorderedMap<ComponentRef, Dependency>> dependencies;
      array<UnorderedMap<ComponentRef, Solvability>> solvabilities;
      array<UnorderedSet<ComponentRef>> repetitions;
      Mapping mapping;
    end FULL;

    record FINAL "specific final matrix, defined by its strictness"
      IntMatrix m                         "eqn -> vars";
      IntMatrix mT                        "var -> eqns";
      Mapping mapping                     "index mapping scalar <-> array";
      ModeTable modes                     "array reconstruction information";
      MatrixStrictness st                 "strictness with which it was created";
    end FINAL;

    record SPARSITY "contains sparsity information to create sparsity patterns for jacobians"
      array<ComponentRef> equation_names;
      array<Iterator> equation_iterators;
      array<UnorderedMap<ComponentRef, Dependency>> dependencies;
      array<UnorderedSet<ComponentRef>> repetitions;
      array<list<ComponentRef>> solved_crefs;
    end SPARSITY;

    function createFull
      input VariablePointers vars;
      input EquationPointers eqns;
      input Partition.Kind kind = NBPartition.Kind.ODE;
      output Matrix adj;
    protected
      Integer index, size = EquationPointers.size(eqns);
      array<ComponentRef> equation_names;
      array<UnorderedSet<ComponentRef>> occurrences;
      array<UnorderedMap<ComponentRef, Dependency>> dependencies;
      array<UnorderedMap<ComponentRef, Solvability>> solvabilities;
      array<UnorderedSet<ComponentRef>> repetitions;
      UnorderedSet<ComponentRef> occ_set, rep_set;
      UnorderedMap<ComponentRef, Dependency> dep_map;
      UnorderedMap<ComponentRef, Solvability> sol_map;
      Mapping mapping;
    algorithm
      // only create matrix if there are any variables or equations
      if ExpandableArray.getNumberOfElements(vars.varArr) > 0 or ExpandableArray.getNumberOfElements(eqns.eqArr) > 0 then
        // create empty arrays for the structures
        equation_names  := arrayCreate(size, ComponentRef.EMPTY());
        occurrences      := arrayCreate(size, UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual));
        dependencies    := arrayCreate(size, UnorderedMap.new<Dependency>(ComponentRef.hash, ComponentRef.isEqual));
        solvabilities   := arrayCreate(size, UnorderedMap.new<Solvability>(ComponentRef.hash, ComponentRef.isEqual));
        repetitions     := arrayCreate(size, UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual));
        // loop over each equation and create the corresponding maps and sets
        for eqn_ptr in EquationPointers.toList(eqns) loop
          index   := UnorderedMap.getSafe(Equation.getEqnName(eqn_ptr), eqns.map, sourceInfo());
          dep_map := UnorderedMap.new<Dependency>(ComponentRef.hash, ComponentRef.isEqual);
          sol_map := UnorderedMap.new<Solvability>(ComponentRef.hash, ComponentRef.isEqual);
          rep_set := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
          occ_set := collectDependenciesEquation(Pointer.access(eqn_ptr), kind, vars.map, dep_map, sol_map, rep_set);
          addInitialStartOccurrences(occ_set, dep_map, sol_map, rep_set, kind);
          equation_names[index] := Equation.getEqnName(eqn_ptr);
          occurrences[index]     := occ_set;
          dependencies[index]   := dep_map;
          solvabilities[index]  := sol_map;
          repetitions[index]    := rep_set;
        end for;
        // create the index mapping and the matrix
        mapping := Mapping.create(eqns, vars);
        adj := FULL(equation_names, occurrences, dependencies, solvabilities, repetitions, mapping);
      else
        adj := EMPTY(MatrixStrictness.FULL);
      end if;
      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print(StringUtil.headline_1("Creating Adjacency Matrices") + "\n");
        print(EquationPointers.toString(eqns) + "\n");
        print(VariablePointers.toString(vars) + "\n");
        print(toString(adj, "Full") + "\n");
        print(solvabilityString(adj, "Full") + "\n");
        print(dependencyString(adj, "Full") + "\n");
      end if;
    end createFull;

    function subFull
      "creates the full matrix of a subset of equations and variables from an
      existing one, sharing its per-equation maps. eqn_indices are the indices
      of eqns in full, in the order of eqns."
      input Matrix full;
      input list<Integer> eqn_indices;
      input EquationPointers eqns;
      input VariablePointers vars;
      output Matrix sub;
    protected
      Integer size = listLength(eqn_indices), j = 1;
      array<ComponentRef> equation_names;
      array<UnorderedSet<ComponentRef>> occurrences, repetitions;
      array<UnorderedMap<ComponentRef, Dependency>> dependencies;
      array<UnorderedMap<ComponentRef, Solvability>> solvabilities;
    algorithm
      sub := match full
        case FULL() guard(size > 0) algorithm
          equation_names  := arrayCreate(size, ComponentRef.EMPTY());
          occurrences     := arrayCreate(size, UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual));
          dependencies    := arrayCreate(size, UnorderedMap.new<Dependency>(ComponentRef.hash, ComponentRef.isEqual));
          solvabilities   := arrayCreate(size, UnorderedMap.new<Solvability>(ComponentRef.hash, ComponentRef.isEqual));
          repetitions     := arrayCreate(size, UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual));
          for i in eqn_indices loop
            equation_names[j] := full.equation_names[i];
            occurrences[j]    := full.occurrences[i];
            dependencies[j]   := full.dependencies[i];
            solvabilities[j]  := full.solvabilities[i];
            repetitions[j]    := full.repetitions[i];
            j := j + 1;
          end for;
        then FULL(equation_names, occurrences, dependencies, solvabilities, repetitions, Mapping.create(eqns, vars));
        else EMPTY(MatrixStrictness.FULL);
      end match;
    end subFull;

    function fullToFinal
      input Matrix full;
      input UnorderedMap<ComponentRef, Integer> vars_map;
      input UnorderedMap<ComponentRef, Integer> eqns_map;
      input EquationPointers eqns;
      input MatrixStrictness st;
      input Iterator iter = Iterator.EMPTY() "optional iterator the whole system might be surrounded by";
      output Matrix adj = upgrade(EMPTY(MatrixStrictness.FULL), full, vars_map, eqns_map, eqns, st, iter);
    end fullToFinal;

    function fullToSparsity
      input Matrix full;
      input list<StrongComponent> comps;
      input UnorderedSet<ComponentRef> seed_set;
      input UnorderedSet<ComponentRef> pder_set;
      input UnorderedMap<ComponentRef, ComponentRef> diff_map;
      input Boolean isAdjoint = false;
      output Matrix sparsity;

      type Dependencies = list<ComponentRef>;
      function filterSet
        input ComponentRef cref;
        input UnorderedSet<ComponentRef> set;
        output Boolean b = UnorderedSet.contains(cref, set) or
                           UnorderedSet.contains(ComponentRef.stripSubscriptsAll(cref), set);
      end filterSet;

      function expandSlice
        "a slice (e.g. i[1:2]) whose elements are seeds depends on each of the elements"
        input ComponentRef cref;
        input UnorderedMap<ComponentRef, ComponentRef> diff_map;
        output list<ComponentRef> crefs;
      protected
        Type ty;
      algorithm
        crefs := {cref};
        if not (UnorderedMap.contains(cref, diff_map) or UnorderedMap.contains(ComponentRef.stripSubscriptsAll(cref), diff_map)) then
          ty := ComponentRef.getSubscriptedType(cref);
          if Type.isArray(ty) and Type.hasKnownSize(ty) and Type.sizeOf(ty) <= 256 then
            crefs := list(c for c guard(UnorderedMap.contains(c, diff_map)) in ComponentRef.scalarizeAll(cref, false));
            if listEmpty(crefs) then
              crefs := {cref};
            end if;
          end if;
        end if;
      end expandSlice;
    algorithm
      sparsity := match full
        local
          UnorderedMap<ComponentRef, Integer> index_map = UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual);
          UnorderedMap<ComponentRef, Dependencies> inner_map = UnorderedMap.new<Dependencies>(ComponentRef.hash, ComponentRef.isEqual);
          UnorderedMap<ComponentRef, Dependencies> inner_keys = UnorderedMap.new<Dependencies>(ComponentRef.hash, ComponentRef.isEqual);
          list<Pointer<Equation>> eqns;
          list<ComponentRef> var_crefs, pder_crefs, tmp_crefs, own_vars;
          ComponentRef eqn_name, dep_cref, seed_cref, pder_cref;
          Option<ComponentRef> oseed_cref;
          Integer eqn_index;
          Iterator iter;
          Dependency dep;
          list<tuple<list<ComponentRef>, Dependency, Boolean>> local_deps;
          Boolean repeated;
          list<ComponentRef> inner_deps;
          Boolean changed;
          Option<list<ComponentRef>> inner_opt;
          UnorderedMap<ComponentRef, Dependency> dep_map;
          UnorderedSet<ComponentRef> rep_set;

          list<ComponentRef> eqn_names = {};
          list<Iterator> eqn_iters = {};
          list<UnorderedMap<ComponentRef, Dependency>> deps = {};
          list<UnorderedSet<ComponentRef>> reps = {};
          list<list<ComponentRef>> solved_crefs = {};
          list<ComponentRef> iter_names;
          UnorderedSet<ComponentRef> own_iters;
          UnorderedMap<ComponentRef, Dependencies> seed_elements = UnorderedMap.new<Dependencies>(ComponentRef.hash, ComponentRef.isEqual);
          UnorderedSet<ComponentRef> no_iters = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
          UnorderedMap<ComponentRef, SliceAliases> slice_map = UnorderedMap.new<SliceAliases>(ComponentRef.hash, ComponentRef.isEqual);
          UnorderedMap<ComponentRef, InnerTemplates> template_map = UnorderedMap.new<InnerTemplates>(ComponentRef.hash, ComponentRef.isEqual);
          Boolean handled;
          list<ComponentRef> alias_deps, template_deps;
          UnorderedMap<ComponentRef, Dependency> eqn_deps;
          Iterator eqn_iter;
          UnorderedMap<ComponentRef, ComponentRef> origins;
          list<ComponentRef> template_crefs;
          list<ComponentRef> solved_keys;

        case FULL() algorithm
          // create the equation name -> index map
          for i in 1:arrayLength(full.equation_names) loop
            UnorderedMap.add(full.equation_names[i], i, index_map);
          end for;

          // element seeds by variable name, for dependencies with iterators that can not be resolved
          for key in UnorderedMap.keyList(diff_map) loop
            if ComponentRef.hasSubscripts(key) and List.all(ComponentRef.subscriptsAllFlat(key), Subscript.isLiteral)
               and not UnorderedMap.contains(ComponentRef.stripSubscriptsAll(key), diff_map) then
              UnorderedMap.add(ComponentRef.stripSubscriptsAll(key), key :: UnorderedMap.getOrDefault(ComponentRef.stripSubscriptsAll(key), seed_elements, {}), seed_elements);
            end if;
          end for;

          // get only relevant equations
          // check equation name. (STRONG COMPONENTS, NO NEED FOR EQUATIONS?)
          //    if it is EITHER inner or result, map all deps with tmp
          //    if it is an inner equation save the mapping to tmp name -> deps
          //    if it is a result equation save the mapping to final name -> deps
          for comp in comps loop
            eqns      := StrongComponent.getEquations(comp);
            var_crefs := StrongComponent.getVariableCrefs(comp);

            // an algebraic loop of independent blocks gets elementwise dependencies
            handled := StrongComponent.isAlgebraicLoop(comp) and not List.any(var_crefs, function filterSet(set = pder_set))
              and sparsityLoopBlocks(comp, var_crefs, full.dependencies, index_map, seed_set, inner_map, inner_keys, template_map, slice_map, seed_elements);
            for eqn in (if handled then {} else eqns) loop
              eqn_name    := Equation.getEqnName(eqn);
              eqn_index   := UnorderedMap.getSafe(eqn_name, index_map, sourceInfo());
              eqn_iter    := Equation.getForIterator(Pointer.access(eqn));
              eqn_deps    := full.dependencies[eqn_index];
              origins     := UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
              template_crefs := {};
              if listLength(eqns) == 1 and not StrongComponent.isAlgebraicLoop(comp) then
                (eqn_iter, eqn_deps, origins, template_crefs) := sparsityElementwise(Pointer.access(eqn), eqn_iter, eqn_deps, var_crefs);
              end if;

              // map the dependencies with the inner maps
              local_deps  := {};
              changed     := false;
              // the variable a single equation solves is no input of it (the residual of a loop
              // uses the loop variables, they are resolved through the inner equations)
              own_vars := if listLength(eqns) == 1 and not StrongComponent.isAlgebraicLoop(comp) then var_crefs else {};
              for tpl in list(t for t guard(not List.any(own_vars, function ComponentRef.isEqual(cref2 = UnorderedMap.getOrDefault(Util.tuple21(t), origins, Util.tuple21(t)))))
                  in UnorderedMap.toList(eqn_deps)) loop
                (dep_cref, dep) := tpl;
                repeated := UnorderedSet.contains(UnorderedMap.getOrDefault(dep_cref, origins, dep_cref), full.repetitions[eqn_index]);
                (inner_deps, changed) := match UnorderedMap.get(dep_cref, inner_map)
                  // with resizable arrays other slices of the variable (e.g. solved by an algebraic
                  // loop) can have the same iterator but another range, also use their dependencies
                  case SOME(inner_deps) guard Flags.getConfigBool(Flags.RESIZABLE_ARRAYS) and not filterSet(dep_cref, seed_set) and ComponentRef.hasSubscripts(dep_cref) algorithm
                    // only if several components solve slices of it (with the same cref, but other ranges,
                    // or another cref), the variable a single component solves has no other dependencies
                    solved_keys := UnorderedMap.getOrDefault(ComponentRef.stripSubscriptsAll(dep_cref), inner_keys, {});
                    inner_opt := UnorderedMap.get(ComponentRef.stripSubscriptsAll(dep_cref), inner_map);
                    if listLength(solved_keys) > 1 and isSome(inner_opt) then
                      // the templates of the slices address their elements, the iterators of whole
                      // dependencies of other slices can not be matched
                      (handled, template_deps) := sparsityTemplateDeps(dep_cref, template_map);
                      if handled then
                        inner_deps := UnorderedSet.unique_list(listAppend(inner_deps, template_deps), ComponentRef.hash, ComponentRef.isEqual);
                      else
                        inner_deps := UnorderedSet.unique_list(listAppend(inner_deps, List.flatten(list(sparsityExpandForeignIterators(c, no_iters, seed_elements)
                          for c guard not List.contains(inner_deps, c, ComponentRef.isEqual) in Util.getOption(inner_opt)))), ComponentRef.hash, ComponentRef.isEqual);
                      end if;
                    end if;
                  then (inner_deps, true);
                  case SOME(inner_deps) then (inner_deps, true);
                  else algorithm
                    // Base-key fallback for subscripted inner LS vars (partial-slice NLS).
                    // Guard prevents outer seed elements (which strip to the same base key
                    // that may be in inner_map) from being misclassified as inner deps.
                    inner_deps := {dep_cref};
                    alias_deps := if filterSet(dep_cref, seed_set) then {} else sparsitySliceAliasDeps(dep_cref, slice_map);
                    handled := false;
                    template_deps := {};
                    if not filterSet(dep_cref, seed_set) then
                      (handled, template_deps) := sparsityTemplateDeps(dep_cref, template_map);
                    end if;
                    if not listEmpty(alias_deps) then
                      inner_deps := dep_cref :: alias_deps;
                      changed := true;
                    elseif handled then
                      inner_deps := dep_cref :: template_deps;
                      changed := true;
                    elseif not filterSet(dep_cref, seed_set) then
                      inner_opt := UnorderedMap.get(ComponentRef.stripSubscriptsAll(dep_cref), inner_map);
                      if isSome(inner_opt) then
                        // keep the cref itself, other elements of the same array might be seeds.
                        // iterators of the found dependencies belong to another equation and can not be
                        // matched with the ones of this equation (e.g. x[i+1] = y[i]), use all elements
                        inner_deps := dep_cref :: List.flatten(list(sparsityExpandForeignIterators(c, no_iters, seed_elements) for c in Util.getOption(inner_opt)));
                        changed := true;
                      end if;
                    end if;
                  then (inner_deps, changed);
                end match;
                local_deps := (inner_deps, dep, repeated) :: local_deps;
              end for;

              (pder_crefs, tmp_crefs) := List.splitOnTrue(var_crefs, function filterSet(set = pder_set));

              // handle result rows
              if not listEmpty(pder_crefs) then
               // create a new dependency map for this row and get all relevant seeds
                dep_map := UnorderedMap.new<Dependency>(ComponentRef.hash, ComponentRef.isEqual);
                rep_set := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
                (iter_names, _, _) := Iterator.getFrames(eqn_iter);
                own_iters := UnorderedSet.fromList(iter_names, ComponentRef.hash, ComponentRef.isEqual);
                for tpl in local_deps loop
                  // this might lead to duplicate occurrences. can and should not be optimized here
                  // as dependency information might not be combinable. optimize afterwards!
                  // ToDo: combine dependencies
                  (inner_deps, dep, repeated) := tpl;
                  inner_deps := List.flatten(list(sparsityExpandForeignIterators(c, own_iters, seed_elements) for c in inner_deps));
                  for dep_cref in List.flatten(list(expandSlice(c, diff_map) for c in inner_deps)) loop
                    if filterSet(dep_cref, seed_set) then
                      // Try subscripted key first (NLS with per-element scalar seeds), then
                      // base key with subscript copy (ODE/DAE with full-array base seeds).
                      // Not found in either: not one of this Jacobian's own unknowns, so its
                      // partial derivative here is zero -- skip instead of erroring.
                      oseed_cref := match UnorderedMap.get(dep_cref, diff_map)
                        case SOME(seed_cref) then SOME(seed_cref);
                        else match UnorderedMap.get(ComponentRef.stripSubscriptsAll(dep_cref), diff_map)
                          // Strip subscripts from the base seed before copying so that
                          // origin subscripts (iterator or literal) merge onto an empty
                          // template rather than clashing with existing literal subscripts.
                          case SOME(seed_cref) then SOME(ComponentRef.copySubscripts(dep_cref, ComponentRef.stripSubscriptsAll(seed_cref)));
                          else NONE();
                        end match;
                      end match;
                      if isSome(oseed_cref) then
                        seed_cref := Util.getOption(oseed_cref);
                        UnorderedMap.add(seed_cref, dep, dep_map);
                        if repeated then
                          UnorderedSet.add(seed_cref, rep_set);
                        end if;
                      end if;
                    end if;
                  end for;
                end for;

                sparsityRemoveCovered(dep_map, rep_set);

                // Store result variables (state derivatives) in inner_map so later
                // result equations can trace transitive dependencies through them.
                // e.g. der(x_i) = f(der(x_j), x_k) with der(x_j) = g(x_s) -> x_s dep.
                if changed then
                  inner_deps := List.flatten(list(Util.tuple31(tpl) for tpl in local_deps));
                  inner_deps := UnorderedSet.unique_list(inner_deps, ComponentRef.hash, ComponentRef.isEqual);
                else
                  inner_deps := UnorderedMap.keyList(eqn_deps);
                end if;
                inner_deps := List.filterOnTrue(List.flatten(list(expandSlice(c, diff_map) for c in inner_deps)), function filterSet(set = seed_set));
                for cref in pder_crefs loop
                  sparsityAddInner(cref, inner_deps, inner_map, inner_keys);
                  sparsityAddTemplate(sparsityTemplateKey(cref, template_crefs), inner_deps, template_map);
                end for;

                if isAdjoint then
                  // The adjoint evaluates rows of the primal Jacobian. Map each
                  // primal result row to its adjoint seed variable. The runtime
                  // later transposes the generated primal CSC pattern to CSR.
                  pder_crefs := list(
                    match UnorderedMap.get(ComponentRef.stripSubscriptsAll(cref), diff_map)
                      case SOME(pder_cref) then ComponentRef.copySubscripts(cref, pder_cref);
                      else algorithm
                        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed because no adjoint seed was found for "
                          + ComponentRef.toString(cref) + " in diff_map."});
                      then fail();
                    end match
                  for cref in pder_crefs);
                else
                  try
                    pder_crefs := list(BVariable.getPartnerCref(cref, function BVariable.getVarPDer(isTmp = false)) for cref in pder_crefs);
                  else
                    Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for " + List.toString(pder_crefs, ComponentRef.toString)
                      + " because they were supposed to be a row vars but at least one does not have a corresponding partial derivative."});
                    fail();
                  end try;
                end if;

                // save the row/result dependencies
                // get the iterators (potentially need local iterators?)
                eqn_names     := eqn_name :: eqn_names;
                eqn_iters     := eqn_iter :: eqn_iters;
                deps          := dep_map :: deps;
                reps          := rep_set :: reps;
                solved_crefs  := pder_crefs :: solved_crefs;
              end if;

              // handle inner temporary dependencies
              if not listEmpty(tmp_crefs) then
               if changed then
                  // some dependencies were mapped. additional dependency information is irrelevant
                  inner_deps := List.flatten(list(Util.tuple31(tpl) for tpl in local_deps));
                  inner_deps := UnorderedSet.unique_list(inner_deps, ComponentRef.hash, ComponentRef.isEqual);
                else
                  // nothing changed, just use the original dependencies
                  inner_deps := UnorderedMap.keyList(eqn_deps);
                end if;

                // filter inner dependencies for relevant seeds and add
                inner_deps := List.filterOnTrue(List.flatten(list(expandSlice(c, diff_map) for c in inner_deps)), function filterSet(set = seed_set));
                // with resizable arrays the variables of an algebraic loop depend on whole arrays,
                // the iterators of its equations do not correspond to the ones of other equations
                // (dependencies without iterators, e.g. x[2, N], stay exact)
                if Flags.getConfigBool(Flags.RESIZABLE_ARRAYS) and StrongComponent.isAlgebraicLoop(comp) then
                  inner_deps := UnorderedSet.unique_list(list(if sparsityCrefHasIterator(c) then ComponentRef.stripSubscriptsAll(c) else c
                    for c in inner_deps), ComponentRef.hash, ComponentRef.isEqual);
                end if;
                for cref in tmp_crefs loop
                  sparsityAddInner(cref, inner_deps, inner_map, inner_keys);
                  sparsityAddTemplate(sparsityTemplateKey(cref, template_crefs), inner_deps, template_map);
                end for;
                sparsityAddSliceAlias(Pointer.access(eqn), tmp_crefs, seed_set, slice_map);
              end if;
            end for;
          end for;
        then SPARSITY(
          equation_names      = listArray(listReverse(eqn_names)),
          equation_iterators  = listArray(listReverse(eqn_iters)),
          dependencies        = listArray(listReverse(deps)),
          repetitions         = listArray(listReverse(reps)),
          solved_crefs        = listArray(listReverse(solved_crefs)));

        case EMPTY() then SPARSITY(
          equation_names      = listArray({}),
          equation_iterators  = listArray({}),
          dependencies        = listArray({}),
          repetitions         = listArray({}),
          solved_crefs        = listArray({}));

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong matrix type.
            Expected: full, Got :" + strictnessString(getStrictness(full)) + "."});
        then fail();
      end match;

      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print(toString(sparsity) + "\n");
      end if;
    end fullToSparsity;

    function sparsityElementwise
      "An array equation without for-iterators whose array occurrences are all elementwise
      (regular dependencies), e.g. y = (x[1:n-1] - x[2:n]) * k, is the for-equation over its
      elements: y[i] = (x[i] - x[1 + i]) * k. Returns that iterator, the dependencies
      subscripted with it (x[2:n] -> x[1 + i], x -> x[i]), the original cref of every
      rewritten dependency and the solved variables subscripted with it (templates for
      inner equations, see sparsityTemplateDeps), so that rows and inner dependencies are
      elementwise instead of depending on whole slices. Only one-dimensional equations
      solving whole arrays are handled, the row of y[i] is the position of i. Anything
      else returns the inputs unchanged."
      input Equation eqn;
      input output Iterator iter;
      input output UnorderedMap<ComponentRef, Dependency> deps;
      output UnorderedMap<ComponentRef, ComponentRef> origins = UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
      output list<ComponentRef> templates = {};
      input list<ComponentRef> solved;
    protected
      Dimension dim;
      ComponentRef iter_cref, cref;
      Expression iter_exp;
      Dependency dep;
      Boolean ok;
      UnorderedMap<ComponentRef, Dependency> new_deps;
    algorithm
      if not Iterator.isEmpty(iter) then
        return;
      end if;
      (ok, dim) := match eqn
        case Equation.ARRAY_EQUATION(ty = Type.ARRAY(dimensions = {dim})) guard(isNone(eqn.recordSize)) then (true, dim);
        else (false, Dimension.UNKNOWN());
      end match;
      if not ok or listEmpty(solved) or not List.all(solved, sparsityIsWhole1D) then
        return;
      end if;

      iter_cref := BackendDAE.lowerIteratorCref(ComponentRef.makeIterator(InstNode.newUniqueIterator(), Type.INTEGER()));
      iter_exp := Expression.fromCref(iter_cref);
      new_deps := UnorderedMap.new<Dependency>(ComponentRef.hash, ComponentRef.isEqual);
      for tpl in UnorderedMap.toList(deps) loop
        (cref, dep) := tpl;
        if Type.isArray(ComponentRef.getSubscriptedType(cref)) then
          (cref, ok) := sparsityElementCref(cref, dep, iter_exp);
          if not ok then
            break;
          end if;
          UnorderedMap.add(cref, Util.tuple21(tpl), origins);
          dep := Dependency.DEPENDENCY(arrayCreate(arrayLength(dep.skips), {}), {});
        end if;
        UnorderedMap.add(cref, dep, new_deps);
      end for;
      // return after the loop, not inside it: the Rust port moves deps into the loop
      if not ok then
        origins := UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
        return;
      end if;

      deps := new_deps;
      templates := list(ComponentRef.setSubscripts({Subscript.INDEX(iter_exp)}, c) for c in solved);
      iter := Iterator.SINGLE(iter_cref, Expression.RANGE(Type.ARRAY(Type.INTEGER(), {dim}), Expression.INTEGER(1), NONE(), Dimension.sizeExp(dim)), NONE());
    end sparsityElementwise;

    function sparsityResolveLookups
      "x[{a, a + 1, ..., b}[e]] -> x[a - 1 + e]. The bound index e of an inner equation can be
      outside of its range for some rows (e.g. i - 1 for i = 1), where the lookup in the
      generated pattern code fails, but a plain index only addresses a wrong column. Any
      other subscript that indexes an expression gives the whole variable."
      input output ComponentRef cref;
    protected
      list<Subscript> subs;
      Boolean ok = true;
    algorithm
      if not ComponentRef.hasSubscripts(cref) or listLength(ComponentRef.subscriptsAllFlat(cref)) <> listLength(ComponentRef.getSubscripts(cref)) then
        return;
      end if;
      subs := list(match s
          local
            Expression e, index;
            array<Expression> e_arr;
          case Subscript.INDEX(index = Expression.SUBSCRIPTED_EXP(exp = Expression.ARRAY(elements = e_arr), subscripts = {Subscript.INDEX(index = index)}))
            guard(sparsityIsUnitRange(arrayList(e_arr)))
            then Subscript.INDEX(sparsitySimplify(Expression.MULTARY({Expression.INTEGER(Expression.integerValue(arrayGet(e_arr, 1))), index},
              {Expression.INTEGER(1)}, Operator.makeAdd(Type.INTEGER()))));
          case Subscript.INDEX(index = e) guard(Expression.contains(e, sparsityIsLookup)) algorithm
            ok := false;
          then s;
          else s;
        end match for s in ComponentRef.getSubscripts(cref));
      cref := if ok then ComponentRef.setSubscripts(subs, cref) else ComponentRef.stripSubscriptsAll(cref);
    end sparsityResolveLookups;

    function sparsityIsUnitRange
      input list<Expression> elems;
      output Boolean b = not listEmpty(elems);
    protected
      Integer next;
    algorithm
      if not b or not Expression.isInteger(listHead(elems)) then
        b := false;
        return;
      end if;
      next := Expression.integerValue(listHead(elems));
      for e in elems loop
        if not (Expression.isInteger(e) and Expression.integerValue(e) == next) then
          b := false;
          return;
        end if;
        next := next + 1;
      end for;
    end sparsityIsUnitRange;

    function sparsityIsLookup
      input Expression exp;
      output Boolean b;
    algorithm
      b := match exp
        case Expression.SUBSCRIPTED_EXP() then true;
        else false;
      end match;
    end sparsityIsLookup;

    function sparsityTemplateKey
      "the element of a solved variable an elementwise array equation solves (see
      sparsityElementwise), else the variable. A whole array as key can not be matched
      with the subscripts of other equations."
      input ComponentRef cref;
      input list<ComponentRef> templates;
      output ComponentRef key = cref;
    algorithm
      for t in templates loop
        if ComponentRef.isEqual(ComponentRef.stripSubscripts(t), cref) then
          key := t;
          return;
        end if;
      end for;
    end sparsityTemplateKey;

    function sparsityIsWhole1D
      input ComponentRef cref;
      output Boolean b = not ComponentRef.hasSubscripts(cref) and Type.dimensionCount(ComponentRef.nodeType(cref)) == 1
        and Type.dimensionCount(ComponentRef.getSubscriptedType(cref)) == 1;
    end sparsityIsWhole1D;

    function sparsityElementCref
      "x -> x[i], x[a:b] -> x[a - 1 + i] for a one-dimensional elementwise occurrence"
      input output ComponentRef cref;
      input Dependency dep;
      input Expression iter_exp;
      output Boolean ok = false;
    protected
      list<Subscript> subs = ComponentRef.getSubscripts(cref);
      Expression index;
    algorithm
      if Type.dimensionCount(ComponentRef.getSubscriptedType(cref)) <> 1 or Type.dimensionCount(ComponentRef.nodeType(cref)) <> 1
         or listLength(ComponentRef.subscriptsAllFlat(cref)) <> listLength(subs)
         or List.any(dep.kinds, Dependency.isReductionKind) then
        return;
      end if;
      (ok, index) := match subs
        local
          Expression start;
        case {} then (true, iter_exp);
        case {Subscript.WHOLE()} then (true, iter_exp);
        case {Subscript.SLICE(slice = Expression.RANGE(start = start, step = NONE()))} then (true,
          sparsitySimplify(Expression.MULTARY({start, iter_exp}, {Expression.INTEGER(1)}, Operator.makeAdd(Type.INTEGER()))));
        case {Subscript.SLICE(slice = Expression.RANGE(start = start, step = SOME(Expression.INTEGER(1))))} then (true,
          sparsitySimplify(Expression.MULTARY({start, iter_exp}, {Expression.INTEGER(1)}, Operator.makeAdd(Type.INTEGER()))));
        else (false, iter_exp);
      end match;
      if ok then
        cref := ComponentRef.setSubscripts({Subscript.INDEX(index)}, cref);
      end if;
    end sparsityElementCref;

    type LoopDimMap = tuple<Integer, Expression> "dimension of the block frame (0: fixed index) and offset or fixed index";
    type LoopMap = list<LoopDimMap>;

    function sparsityLoopBlocks
      "An algebraic loop of for-equations is a set of independent blocks if every loop variable
      occurs with the same shift relative to the block (the frame of the residual): each frame
      dimension of an equation is a shifted block dimension (j_p = i_k + d) or fixed (j_p = 1), such
      that each occurrence v[j + o] gives the same index map of v in the block, and fixed subscripts
      (v[i, 1]) are equal. Then every loop variable element of block i depends on the seeds of all
      equations of block i only.
      Adds the templates of the loop variables and returns true, false (nothing added) if the
      shifts are not consistent, e.g. v[i] and v[i + 1] in one block."
      input StrongComponent comp;
      input list<ComponentRef> var_crefs;
      input array<UnorderedMap<ComponentRef, Dependency>> dependencies;
      input UnorderedMap<ComponentRef, Integer> index_map;
      input UnorderedSet<ComponentRef> seed_set;
      input UnorderedMap<ComponentRef, list<ComponentRef>> inner_map;
      input UnorderedMap<ComponentRef, list<ComponentRef>> inner_keys;
      input UnorderedMap<ComponentRef, InnerTemplates> template_map;
      input UnorderedMap<ComponentRef, SliceAliases> slice_map;
      input UnorderedMap<ComponentRef, list<ComponentRef>> seed_elements;
      output Boolean success = false;
    protected
      list<Pointer<Equation>> eqns;
      UnorderedSet<ComponentRef> loop_vars = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
      list<tuple<ComponentRef, list<ComponentRef>, list<ComponentRef>, list<ComponentRef>>> infos = {} "name, frame iterators, loop var occurrences, other dependencies";
      UnorderedMap<ComponentRef, LoopMap> shifts = UnorderedMap.new<LoopMap>(ComponentRef.hash, ComponentRef.isEqual) "frame transforms of the equations";
      UnorderedMap<ComponentRef, list<LoopDimMap>> maps = UnorderedMap.new<LoopMap>(ComponentRef.hash, ComponentRef.isEqual);
      UnorderedMap<ComponentRef, ComponentRef> keys = UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
      list<ComponentRef> block_iters, frame, occs, others, seeds = {}, deps;
      ComponentRef eqn_name, stripped;
      Integer eqn_index, n;
      Iterator iter;
      Boolean changed, ok;
      LoopMap d;
      Option<LoopMap> od;
      list<LoopDimMap> m;
      UnorderedSet<ComponentRef> own_iters;
      array<StrongComponent> inner_comps;
    algorithm
      for v in var_crefs loop
        UnorderedSet.add(ComponentRef.stripSubscriptsAll(v), loop_vars);
      end for;

      // residual equations first, the first one defines the block frame
      () := match StrongComponent.removeAlias(comp)
        case StrongComponent.ALGEBRAIC_LOOP(strict = NBTearing.TEARING_SET(innerEquations = inner_comps)) algorithm
          eqns := List.flatten(list(StrongComponent.getEquations(c) for c in inner_comps));
          eqns := listAppend(StrongComponent.getEquations(comp), eqns);
        then ();
        else algorithm return; then ();
      end match;
      for eqn in eqns loop
        eqn_name := Equation.getEqnName(eqn);
        if not UnorderedMap.contains(eqn_name, index_map) then return; end if;
        eqn_index := UnorderedMap.getSafe(eqn_name, index_map, sourceInfo());
        iter := Equation.getForIterator(Pointer.access(eqn));
        (frame, _, _) := Iterator.getFrames(iter);
        if listEmpty(frame) then return; end if;
        (occs, others) := List.splitOnTrue(UnorderedMap.keyList(dependencies[eqn_index]),
          function sparsityInSet(set = loop_vars));
        infos := (eqn_name, frame, occs, others) :: infos;
      end for;
      infos := listReverse(infos);
      (_, block_iters, _, _) := listHead(infos);
      n := listLength(block_iters);
      UnorderedMap.add(Util.tuple41(listHead(infos)), list((k, Expression.INTEGER(0)) for k in 1:n), shifts);

      // propagate the shifts of the equations and the index maps of the loop variables
      changed := true;
      while changed loop
        changed := false;
        for info in infos loop
          (eqn_name, frame, occs, _) := info;
          od := UnorderedMap.get(eqn_name, shifts);
          if isNone(od) then
            for c in occs loop
              if UnorderedMap.contains(ComponentRef.stripSubscriptsAll(c), maps) then
                (ok, d) := sparsityLoopShift(c, frame, UnorderedMap.getSafe(ComponentRef.stripSubscriptsAll(c), maps, sourceInfo()));
                if not ok then return; end if;
                UnorderedMap.add(eqn_name, d, shifts);
                od := SOME(d);
                changed := true;
                break;
              end if;
            end for;
          end if;
          if isSome(od) then
            SOME(d) := od;
            for c in occs loop
              (ok, m) := sparsityLoopMap(c, frame, d);
              if not ok then return; end if;
              stripped := ComponentRef.stripSubscriptsAll(c);
              if UnorderedMap.contains(stripped, maps) then
                if not sparsityLoopMapEqual(m, UnorderedMap.getSafe(stripped, maps, sourceInfo())) then return; end if;
              else
                UnorderedMap.add(stripped, m, maps);
                UnorderedMap.add(stripped, sparsityLoopToBlock(c, frame, d, block_iters), keys);
                changed := true;
              end if;
            end for;
          end if;
        end for;
      end while;
      // every equation is placed and every loop variable has a map
      if List.any(list(not UnorderedMap.contains(Util.tuple41(i), shifts) for i in infos), Util.id)
         or List.any(list(not UnorderedMap.contains(v, maps) for v in UnorderedSet.toList(loop_vars)), Util.id) then
        return;
      end if;

      // the seeds of the block: the other dependencies of all equations in the block frame
      for info in infos loop
        (eqn_name, frame, _, others) := info;
        d := UnorderedMap.getSafe(eqn_name, shifts, sourceInfo());
        own_iters := UnorderedSet.fromList(frame, ComponentRef.hash, ComponentRef.isEqual);
        for c in others loop
          deps := sparsityLoopResolve(c, seed_set, inner_map, template_map, slice_map);
          deps := List.flatten(list(sparsityExpandForeignIterators(x, own_iters, seed_elements) for x in deps));
          for x in deps loop
            if sparsityInSet(x, seed_set) or UnorderedSet.contains(x, seed_set) then
              seeds := sparsityLoopToBlock(x, frame, d, block_iters) :: seeds;
            end if;
          end for;
        end for;
      end for;
      seeds := UnorderedSet.unique_list(seeds, ComponentRef.hash, ComponentRef.isEqual);

      for v in UnorderedSet.toList(loop_vars) loop
        sparsityAddInner(v, list(if sparsityCrefHasIterator(c) then ComponentRef.stripSubscriptsAll(c) else c for c in seeds), inner_map, inner_keys);
        sparsityAddTemplate(UnorderedMap.getSafe(v, keys, sourceInfo()), seeds, template_map);
      end for;
      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print("[sparsityLoopBlocks] independent blocks " + List.toString(list(UnorderedMap.getSafe(v, keys, sourceInfo()) for v in UnorderedSet.toList(loop_vars)), ComponentRef.toString)
          + " depend on " + List.toString(seeds, ComponentRef.toString) + "\n");
      end if;
      success := true;
    end sparsityLoopBlocks;

    function sparsityInSet
      input ComponentRef cref;
      input UnorderedSet<ComponentRef> set;
      output Boolean b = UnorderedSet.contains(ComponentRef.stripSubscriptsAll(cref), set);
    end sparsityInSet;

    function sparsityLoopSub
      "(frame dimension, offset) of an iterator subscript i_k + o, (0, e) of a subscript without iterators"
      input Subscript sub;
      input list<ComponentRef> frame;
      output Boolean ok = false;
      output LoopDimMap dim = (0, Expression.INTEGER(0));
    protected
      Expression e, offset;
      ComponentRef iter;
      Boolean negated;
      Integer k;
    algorithm
      () := match sub
        case Subscript.INDEX(index = e) algorithm
          if not sparsityHasIterator(e) then
            ok := true;
            dim := (0, sparsitySimplify(e));
          else
            (ok, iter, offset, negated) := sparsityIteratorOffset(e);
            k := List.positionOnTrue(frame, function ComponentRef.isEqual(cref2 = iter));
            ok := ok and not negated and k > 0;
            dim := (k, sparsitySimplify(offset));
          end if;
        then ();
        else ();
      end match;
    end sparsityLoopSub;

    function sparsityLoopMap
      "the index map of an occurrence in an equation with the frame transform d"
      input ComponentRef cref;
      input list<ComponentRef> frame;
      input LoopMap d;
      output Boolean ok = true;
      output list<LoopDimMap> map = {};
    protected
      Boolean b;
      LoopDimMap dim;
    algorithm
      for sub in ComponentRef.subscriptsAllFlat(cref) loop
        (b, dim) := sparsityLoopSub(sub, frame);
        if not b then
          ok := false;
          return;
        end if;
        if Util.tuple21(dim) > 0 then
          // j_p + o with j_p = i_k + c or j_p = c
          dim := (Util.tuple21(listGet(d, Util.tuple21(dim))), sparsitySimplify(Expression.MULTARY(
            {Util.tuple22(dim), Util.tuple22(listGet(d, Util.tuple21(dim)))}, {}, Operator.makeAdd(Type.INTEGER()))));
        end if;
        map := dim :: map;
      end for;
      map := listReverse(map);
    end sparsityLoopMap;

    function sparsityLoopShift
      "the frame transform of an equation from an occurrence and the index map of its variable"
      input ComponentRef cref;
      input list<ComponentRef> frame;
      input list<LoopDimMap> map;
      output Boolean ok = true;
      output LoopMap d = {};
    protected
      array<Option<LoopDimMap>> ds = arrayCreate(listLength(frame), NONE());
      LoopDimMap target, entry;
      list<Subscript> subs = ComponentRef.subscriptsAllFlat(cref);
      Boolean b;
      LoopDimMap dim;
      Expression shift;
    algorithm
      if listLength(subs) <> listLength(map) then
        ok := false;
        return;
      end if;
      for tpl in List.zip(subs, map) loop
        (b, dim) := sparsityLoopSub(Util.tuple21(tpl), frame);
        target := Util.tuple22(tpl);
        if not b then
          ok := false;
          return;
        end if;
        if Util.tuple21(dim) > 0 then
          // j_p + o = i_k + c (or the fixed index c): j_p = i_k + c - o (or c - o)
          shift := sparsitySimplify(Expression.BINARY(Util.tuple22(target), Operator.makeSub(Type.INTEGER()), Util.tuple22(dim)));
          entry := (Util.tuple21(target), shift);
          if isSome(ds[Util.tuple21(dim)]) then
            if not sparsityLoopMapEqual({Util.getOption(ds[Util.tuple21(dim)])}, {entry}) then
              ok := false;
              return;
            end if;
          end if;
          arrayUpdate(ds, Util.tuple21(dim), SOME(entry));
        elseif not sparsityLoopMapEqual({dim}, {target}) then
          // a fixed subscript has to address the same fixed index
          ok := false;
          return;
        end if;
      end for;
      if Array.any(ds, isNone) then
        ok := false;
        return;
      end if;
      d := list(Util.getOption(o) for o in ds);
    end sparsityLoopShift;

    function sparsityLoopMapEqual
      input list<LoopDimMap> m1;
      input list<LoopDimMap> m2;
      output Boolean b = listLength(m1) == listLength(m2);
    algorithm
      if b then
        for tpl in List.zip(m1, m2) loop
          if Util.tuple21(Util.tuple21(tpl)) <> Util.tuple21(Util.tuple22(tpl))
             or not Expression.isEqual(Util.tuple22(Util.tuple21(tpl)), Util.tuple22(Util.tuple22(tpl))) then
            b := false;
            return;
          end if;
        end for;
      end if;
    end sparsityLoopMapEqual;

    function sparsityLoopToBlock
      "a cref of an equation in the frame of the block: j_p -> i_k + c (or c)"
      input ComponentRef cref;
      input list<ComponentRef> frame;
      input LoopMap d;
      input list<ComponentRef> block_iters;
      output ComponentRef res;
    protected
      UnorderedMap<ComponentRef, Expression> bindings = UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
    algorithm
      for tpl in List.zip(frame, d) loop
        UnorderedMap.add(Util.tuple21(tpl), if Util.tuple21(Util.tuple22(tpl)) > 0
          then sparsitySimplify(Expression.MULTARY({Expression.fromCref(listGet(block_iters, Util.tuple21(Util.tuple22(tpl)))), Util.tuple22(Util.tuple22(tpl))}, {},
            Operator.makeAdd(Type.INTEGER())))
          else Util.tuple22(Util.tuple22(tpl)), bindings);
      end for;
      res := ComponentRef.mapExp(ComponentRef.mapExp(cref, function sparsityBind(bindings = bindings)), sparsitySimplify);
    end sparsityLoopToBlock;

    function sparsityLoopResolve
      "the dependencies of a cref that is no loop variable, like for the other equations"
      input ComponentRef cref;
      input UnorderedSet<ComponentRef> seed_set;
      input UnorderedMap<ComponentRef, list<ComponentRef>> inner_map;
      input UnorderedMap<ComponentRef, InnerTemplates> template_map;
      input UnorderedMap<ComponentRef, SliceAliases> slice_map;
      output list<ComponentRef> deps = {cref};
    protected
      list<ComponentRef> alias_deps, template_deps;
      Boolean handled;
      Option<list<ComponentRef>> opt;
    algorithm
      if sparsityInSet(cref, seed_set) or UnorderedSet.contains(cref, seed_set) then
        return;
      end if;
      opt := UnorderedMap.get(cref, inner_map);
      if isSome(opt) then
        deps := Util.getOption(opt);
        return;
      end if;
      alias_deps := sparsitySliceAliasDeps(cref, slice_map);
      if not listEmpty(alias_deps) then
        deps := alias_deps;
        return;
      end if;
      (handled, template_deps) := sparsityTemplateDeps(cref, template_map);
      if handled then
        deps := template_deps;
        return;
      end if;
      opt := UnorderedMap.get(ComponentRef.stripSubscriptsAll(cref), inner_map);
      if isSome(opt) then
        // dependencies of another equation, their iterators are expanded by the caller
        deps := Util.getOption(opt);
      end if;
    end sparsityLoopResolve;

    type InnerTemplate = tuple<ComponentRef, list<ComponentRef>> "solved cref with the subscripts of its equation, its dependencies";
    type InnerTemplates = list<InnerTemplate>;
    type UnifyStatus = enumeration(DIFFERENT, MATCHED, UNKNOWN) "the subscripts address different elements, match with bindings or can not be compared";

    function sparsityAddTemplate
      input ComponentRef cref;
      input list<ComponentRef> deps;
      input UnorderedMap<ComponentRef, InnerTemplates> template_map;
    protected
      ComponentRef stripped = ComponentRef.stripSubscriptsAll(cref);
    algorithm
      UnorderedMap.add(stripped, (cref, deps) :: UnorderedMap.getOrDefault(stripped, template_map, {}), template_map);
    end sparsityAddTemplate;

    function sparsityTemplateDeps
      "x[e] from the inner equations solving x[f(i)] with dependencies y[g(i)]: y[g(f^-1(e))].
      Not handled if a subscript can not be matched this way."
      input ComponentRef cref;
      input UnorderedMap<ComponentRef, InnerTemplates> template_map;
      output Boolean handled = false;
      output list<ComponentRef> deps = {};
    protected
      InnerTemplates templates = UnorderedMap.getOrDefault(ComponentRef.stripSubscriptsAll(cref), template_map, {});
      list<Subscript> subs = ComponentRef.subscriptsAllWithWholeFlat(cref);
      UnifyStatus status;
      UnorderedMap<ComponentRef, Expression> bindings;
      ComponentRef key, dep;
      list<ComponentRef> key_deps;
      Boolean matched = false;
    algorithm
      for template in templates loop
        (key, key_deps) := template;
        (status, bindings) := sparsityUnify(ComponentRef.subscriptsAllWithWholeFlat(key), subs);
        if status == UnifyStatus.UNKNOWN then
          return;
        elseif status == UnifyStatus.MATCHED then
          matched := true;
          for d in key_deps loop
            // an iterator of the inner equation that does not occur in the solved cref addresses all
            // elements, only of the last dimension if the others are bound (the shape codegen supports)
            dep := sparsityWholeLastIfUnbound(d, bindings);
            if sparsityHasUnbound(dep, bindings) then
              deps := ComponentRef.stripSubscriptsAll(d) :: deps;
            else
              dep := ComponentRef.mapExp(ComponentRef.mapExp(dep, function sparsityBind(bindings = bindings)), sparsitySimplify);
              dep := sparsityResolveLookups(dep);
              if sparsityInBounds(dep) then
                deps := dep :: deps;
              end if;
            end if;
          end for;
        end if;
      end for;
      handled := matched;
    end sparsityTemplateDeps;

    function sparsityUnify
      input list<Subscript> key_subs;
      input list<Subscript> subs;
      output UnifyStatus status = UnifyStatus.MATCHED;
      output UnorderedMap<ComponentRef, Expression> bindings = UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
    protected
      Expression key_exp, exp, value, offset;
      Boolean ok, negated;
      ComponentRef iter;
    algorithm
      if listLength(key_subs) <> listLength(subs) then
        status := UnifyStatus.UNKNOWN;
        return;
      end if;
      for tpl in List.zip(key_subs, subs) loop
        () := match tpl
          case (Subscript.WHOLE(), _) then ();
          case (Subscript.SLICE(slice = key_exp), _) guard(not sparsityHasIterator(key_exp)) then ();
          // a literal or a parameter (x[N]) binds nothing, it can only be told apart from another literal
          case (Subscript.INDEX(index = key_exp), _) guard(not sparsityHasIterator(key_exp)) algorithm
            () := match Util.tuple22(tpl)
              case Subscript.INDEX(index = exp) guard(Expression.isInteger(exp) and Expression.isInteger(key_exp)) algorithm
                if Expression.integerValue(exp) <> Expression.integerValue(key_exp) then
                  status := UnifyStatus.DIFFERENT;
                end if;
              then ();
              else ();
            end match;
          then ();
          // a symbolic index without iterators (e.g. x[N] of a resizable array) may match, like a literal
          case (Subscript.INDEX(index = key_exp), _) guard(not Expression.contains(key_exp, Expression.isIterator)) then ();
          // several elements (x[i, :]) leave the iterator unbound, dependencies using it become whole arrays
          case (Subscript.INDEX(), Subscript.WHOLE()) then ();
          case (Subscript.INDEX(), Subscript.SLICE()) then ();
          case (Subscript.INDEX(index = key_exp), Subscript.INDEX(index = exp)) algorithm
            (ok, iter, offset, negated) := sparsityIteratorOffset(key_exp);
            if ok then
              value := if negated
                then SimplifyExp.simplify(Expression.BINARY(offset, Operator.makeSub(Type.INTEGER()), exp))
                else SimplifyExp.simplify(Expression.BINARY(exp, Operator.makeSub(Type.INTEGER()), offset));
              if UnorderedMap.contains(iter, bindings) and not Expression.isEqual(value, UnorderedMap.getSafe(iter, bindings, sourceInfo())) then
                status := UnifyStatus.UNKNOWN;
              else
                UnorderedMap.add(iter, value, bindings);
              end if;
            else
              status := UnifyStatus.UNKNOWN;
            end if;
          then ();
          else algorithm
            status := UnifyStatus.UNKNOWN;
          then ();
        end match;
        if status <> UnifyStatus.MATCHED then
          return;
        end if;
      end for;
    end sparsityUnify;

    function sparsityIteratorOffset
      "i + c, c + i, i - c and i as (i, c, false), c - i as (i, c, true); c without iterators"
      input Expression exp;
      output Boolean ok = true;
      output ComponentRef iter = ComponentRef.EMPTY();
      output Expression offset = Expression.INTEGER(0);
      output Boolean negated = false;
    algorithm
      () := match exp
        case Expression.CREF() guard(ComponentRef.isIterator(exp.cref)) algorithm
          iter := exp.cref;
        then ();
        case Expression.BINARY(exp1 = Expression.CREF(cref = iter), operator = Operator.OPERATOR(op = Op.ADD), exp2 = offset)
          guard(ComponentRef.isIterator(iter) and not sparsityHasIterator(offset)) then ();
        case Expression.BINARY(exp1 = offset, operator = Operator.OPERATOR(op = Op.ADD), exp2 = Expression.CREF(cref = iter))
          guard(ComponentRef.isIterator(iter) and not sparsityHasIterator(offset)) then ();
        case Expression.BINARY(exp1 = Expression.CREF(cref = iter), operator = Operator.OPERATOR(op = Op.SUB), exp2 = offset)
          guard(ComponentRef.isIterator(iter) and not sparsityHasIterator(offset)) algorithm
          offset := Expression.negate(offset);
        then ();
        case Expression.BINARY(exp1 = offset, operator = Operator.OPERATOR(op = Op.SUB), exp2 = Expression.CREF(cref = iter))
          guard(ComponentRef.isIterator(iter) and not sparsityHasIterator(offset)) algorithm
          negated := true;
        then ();
        case Expression.MULTARY(operator = Operator.OPERATOR(op = Op.ADD)) algorithm
          (ok, iter, offset, negated) := sparsityMultaryOffset(exp);
        then ();
        else algorithm
          ok := false;
        then ();
      end match;
    end sparsityIteratorOffset;

    function sparsityHasIterator
      input Expression exp;
      output Boolean b = UnorderedSet.any(Expression.extractCrefs(exp), ComponentRef.isIterator);
    end sparsityHasIterator;

    function sparsityCrefHasIterator
      input ComponentRef cref;
      output Boolean b = List.any(list(sparsityHasIterator(Subscript.toExp(s))
        for s guard(not Subscript.isWhole(s)) in ComponentRef.subscriptsAllFlat(cref)), Util.id);
    end sparsityCrefHasIterator;

    function sparsitySimplify
      "with the sums combined, so that equal subscripts (e.g. 1 + i - 1 and i) are equal crefs"
      input output Expression exp;
    algorithm
      exp := SimplifyExp.simplify(exp);
      exp := SimplifyExp.combineBinaries(exp);
      exp := SimplifyExp.simplify(exp);
    end sparsitySimplify;

    function sparsityWholeLastIfUnbound
      input output ComponentRef cref;
      input UnorderedMap<ComponentRef, Expression> bindings;
    protected
      list<Subscript> subs = listReverse(ComponentRef.subscriptsAllFlat(cref));
      Subscript last;
    algorithm
      if listEmpty(subs) then
        return;
      end if;
      last :: subs := subs;
      if sparsityIsUnboundIndex(last, bindings) and not List.any(subs, function sparsityIsUnboundIndex(bindings = bindings))
         and List.all(subs, Subscript.isIndex) then
        cref := ComponentRef.mapSubscripts(cref, function sparsityWholeIfUnbound(bindings = bindings));
      end if;
    end sparsityWholeLastIfUnbound;

    function sparsityWholeIfUnbound
      input output Subscript sub;
      input UnorderedMap<ComponentRef, Expression> bindings;
    algorithm
      if sparsityIsUnboundIndex(sub, bindings) then
        sub := Subscript.WHOLE();
      end if;
    end sparsityWholeIfUnbound;

    function sparsityIsUnboundIndex
      input Subscript sub;
      input UnorderedMap<ComponentRef, Expression> bindings;
      output Boolean b;
    algorithm
      b := match sub
        case Subscript.INDEX() then UnorderedSet.any(Expression.extractCrefs(sub.index),
          function sparsityIsUnboundIterator(bindings = bindings));
        else false;
      end match;
    end sparsityIsUnboundIndex;

    function sparsityIsUnboundIterator
      input ComponentRef cref;
      input UnorderedMap<ComponentRef, Expression> bindings;
      output Boolean b = ComponentRef.isIterator(cref) and not UnorderedMap.contains(cref, bindings);
    end sparsityIsUnboundIterator;

    function sparsityHasUnbound
      input ComponentRef cref;
      input UnorderedMap<ComponentRef, Expression> bindings;
      output Boolean b = false;
    algorithm
      // whole dimension subscripts (:) have no expression to check
      for sub in list(s for s guard(not Subscript.isWhole(s)) in ComponentRef.subscriptsAllFlat(cref)) loop
        for c in UnorderedSet.toList(Expression.extractCrefs(Subscript.toExp(sub))) loop
          if ComponentRef.isIterator(c) and not UnorderedMap.contains(c, bindings) then
            b := true;
            return;
          end if;
        end for;
      end for;
    end sparsityHasUnbound;

    function sparsityMultaryOffset
      "a sum with one iterator, which may be subtracted, and terms without iterators"
      input Expression exp;
      output Boolean ok = false;
      output ComponentRef iter = ComponentRef.EMPTY();
      output Expression offset = Expression.INTEGER(0);
      output Boolean negated = false;
    protected
      list<Expression> its, inv_its, rest, inv_rest;
    algorithm
      () := match exp
        case Expression.MULTARY() algorithm
          (its, rest) := List.splitOnTrue(exp.arguments, sparsityIsIteratorExp);
          (inv_its, inv_rest) := List.splitOnTrue(exp.inv_arguments, sparsityIsIteratorExp);
          if listLength(its) + listLength(inv_its) == 1 then
            negated := listEmpty(its);
            iter := Expression.toCref(listHead(if negated then inv_its else its));
            offset := Expression.MULTARY(rest, inv_rest, exp.operator);
            ok := not sparsityHasIterator(offset);
          end if;
        then ();
        else ();
      end match;
    end sparsityMultaryOffset;

    function sparsityIsIteratorExp
      input Expression exp;
      output Boolean b = Expression.isCref(exp) and ComponentRef.isIterator(Expression.toCref(exp));
    end sparsityIsIteratorExp;

    function sparsityBind
      input output Expression exp;
      input UnorderedMap<ComponentRef, Expression> bindings;
    algorithm
      exp := match exp
        case Expression.CREF() guard(UnorderedMap.contains(exp.cref, bindings))
        then UnorderedMap.getSafe(exp.cref, bindings, sourceInfo());
        else exp;
      end match;
    end sparsityBind;

    function sparsityInBounds
      "false if a literal subscript is outside of its dimension"
      input ComponentRef cref;
      output Boolean b = true;
    algorithm
      b := match cref
        local
          list<Dimension> dims;
        case ComponentRef.CREF() algorithm
          dims := Type.arrayDims(cref.ty);
          if listLength(dims) == listLength(cref.subscripts) then
            for tpl in List.zip(cref.subscripts, dims) loop
              () := match tpl
                local
                  Expression e;
                  Dimension d;
                case (Subscript.INDEX(index = e), d) guard(Expression.isInteger(e) and Dimension.isKnown(d)) algorithm
                  if Expression.integerValue(e) < 1 or Expression.integerValue(e) > Dimension.size(d) then
                    b := false;
                  end if;
                then ();
                else ();
              end match;
            end for;
          end if;
        then b and sparsityInBounds(cref.restCref);
        else true;
      end match;
    end sparsityInBounds;

    type SliceAlias = tuple<Expression, Expression, ComponentRef, Expression> "solved start, solved stop, seed, seed start";
    type SliceAliases = list<SliceAlias>;

    function sparsityAddSliceAlias
      "remembers x[a:b] = y[c:d] (or whole arrays) of an inner equation solved for x,
      so that x[e] can be resolved to y[e - a + c] instead of all of y"
      input Equation eqn;
      input list<ComponentRef> tmp_crefs;
      input UnorderedSet<ComponentRef> seed_set;
      input UnorderedMap<ComponentRef, SliceAliases> slice_map;
    protected
      ComponentRef lhs, rhs;
    algorithm
      () := match eqn
        case Equation.ARRAY_EQUATION(lhs = Expression.CREF(cref = lhs), rhs = Expression.CREF(cref = rhs)) algorithm
          sparsityAddSliceAlias2(lhs, rhs, tmp_crefs, seed_set, slice_map);
          sparsityAddSliceAlias2(rhs, lhs, tmp_crefs, seed_set, slice_map);
        then ();
        else ();
      end match;
    end sparsityAddSliceAlias;

    function sparsityAddSliceAlias2
      input ComponentRef solved;
      input ComponentRef seed;
      input list<ComponentRef> tmp_crefs;
      input UnorderedSet<ComponentRef> seed_set;
      input UnorderedMap<ComponentRef, SliceAliases> slice_map;
    protected
      ComponentRef solved_base = ComponentRef.stripSubscriptsAll(solved);
      ComponentRef seed_base = ComponentRef.stripSubscriptsAll(seed);
      Boolean ok1, ok2;
      Expression start1, stop1, start2, stop2;
    algorithm
      if not List.any(tmp_crefs, function sparsitySameBase(base = solved_base)) or not UnorderedSet.contains(seed_base, seed_set) then
        return;
      end if;
      (ok1, start1, stop1) := sparsitySliceBounds(solved);
      (ok2, start2, stop2) := sparsitySliceBounds(seed);
      // the sides of an array equation have the same size, only literal bounds can be checked
      if ok1 and ok2 and not (List.all({start1, stop1, start2, stop2}, Expression.isInteger)
         and Expression.integerValue(stop1) - Expression.integerValue(start1) <> Expression.integerValue(stop2) - Expression.integerValue(start2)) then
        UnorderedMap.add(solved_base, (start1, stop1, seed_base, start2) :: UnorderedMap.getOrDefault(solved_base, slice_map, {}), slice_map);
      end if;
    end sparsityAddSliceAlias2;

    function sparsitySameBase
      input ComponentRef cref;
      input ComponentRef base;
      output Boolean b = ComponentRef.isEqual(ComponentRef.stripSubscriptsAll(cref), base);
    end sparsitySameBase;

    function sparsitySliceBounds
      "bounds of a one-dimensional variable or a unit step slice of it"
      input ComponentRef cref;
      output Boolean ok = false;
      output Expression start = Expression.INTEGER(1);
      output Expression stop = Expression.INTEGER(0);
    protected
      Type ty = ComponentRef.getSubscriptedType(ComponentRef.stripSubscriptsAll(cref));
      list<Subscript> subs = ComponentRef.subscriptsAllFlat(cref);
      Integer istart, istep, istop;
      Expression size;
    algorithm
      if Type.dimensionCount(ty) <> 1 or listLength(subs) <> listLength(ComponentRef.getSubscripts(cref)) then
        return;
      end if;
      if Type.hasKnownSize(ty) then
        size := Expression.INTEGER(Type.sizeOf(ty));
      else
        size := match Type.arrayDims(ty)
          local
            Dimension dim;
          case {dim as Dimension.RESIZABLE()} then Dimension.sizeExp(dim);
          case {dim as Dimension.EXP()} then Dimension.sizeExp(dim);
          else Expression.EMPTY(Type.INTEGER());
        end match;
      end if;
      (ok, start, stop) := match subs
        local
          Expression range;
          list<Subscript> indices;
        case {} then (not Expression.isEmpty(size), Expression.INTEGER(1), size);
        case {Subscript.WHOLE()} then (not Expression.isEmpty(size), Expression.INTEGER(1), size);
        case {Subscript.SLICE(slice = range as Expression.RANGE())} guard(Expression.isLiteral(range)) algorithm
          (istart, istep, istop) := Expression.getIntegerRange(range, false);
        then (istep == 1, Expression.INTEGER(istart), Expression.INTEGER(istop));
        case {Subscript.SLICE(slice = range as Expression.RANGE())}
          guard(Util.applyOptionOrDefault(range.step, function Expression.isEqual(exp2 = Expression.INTEGER(1)), true))
        then (true, range.start, range.stop);
        case {Subscript.SLICE(slice = range as Expression.ARRAY())}
        then sparsityConsecutive(Expression.arrayElementList(range));
        case {Subscript.EXPANDED_SLICE(indices = indices)}
        then sparsityConsecutive(list(Subscript.toExp(sub) for sub in indices));
        else (false, start, stop);
      end match;
    end sparsitySliceBounds;

    function sparsityConsecutive
      input list<Expression> indices;
      output Boolean ok;
      output Expression start_exp;
      output Expression stop_exp;
    protected
      Integer start = 0, stop = 0;
    algorithm
      (ok, start, stop) := sparsityConsecutive2(indices);
      start_exp := Expression.INTEGER(start);
      stop_exp := Expression.INTEGER(stop);
    end sparsityConsecutive;

    function sparsityConsecutive2
      input list<Expression> indices;
      output Boolean ok = true;
      output Integer start = 0;
      output Integer stop = 0;
    algorithm
      for index in indices loop
        if not Expression.isInteger(index) then
          ok := false;
          return;
        end if;
        if stop == 0 then
          start := Expression.integerValue(index);
        elseif Expression.integerValue(index) <> stop + 1 then
          ok := false;
          return;
        end if;
        stop := Expression.integerValue(index);
      end for;
      ok := stop > 0;
    end sparsityConsecutive2;

    function sparsitySliceAliasDeps
      "x[e] with a slice alias x[a:b] = y[c:d] -> y[e - a + c]"
      input ComponentRef cref;
      input UnorderedMap<ComponentRef, SliceAliases> slice_map;
      output list<ComponentRef> deps = {};
    protected
      list<SliceAlias> aliases;
      Expression start1, stop1, start2, index;
      ComponentRef seed;
    algorithm
      aliases := UnorderedMap.getOrDefault(ComponentRef.stripSubscriptsAll(cref), slice_map, {});
      if listEmpty(aliases) or listLength(ComponentRef.subscriptsAllFlat(cref)) <> listLength(ComponentRef.getSubscripts(cref)) then
        return;
      end if;
      _ := match ComponentRef.getSubscripts(cref)
        case {Subscript.INDEX(index = index)} algorithm
          for alias in aliases loop
            (start1, stop1, seed, start2) := alias;
            if not (Expression.isInteger(index) and (
                 Expression.isInteger(start1) and Expression.integerValue(index) < Expression.integerValue(start1) or
                 Expression.isInteger(stop1) and Expression.integerValue(index) > Expression.integerValue(stop1))) then
              deps := ComponentRef.setSubscripts({Subscript.INDEX(SimplifyExp.simplify(Expression.BINARY(
                Expression.BINARY(index, Operator.makeAdd(Type.INTEGER()), start2),
                Operator.makeSub(Type.INTEGER()), start1)))}, seed) :: deps;
            end if;
          end for;
        then ();
        else ();
      end match;
    end sparsitySliceAliasDeps;

    function sparsityExpandForeignIterators
      "a dependency with iterators of another (inner) equation depends on all its seed elements"
      input ComponentRef cref;
      input UnorderedSet<ComponentRef> own_iters;
      input UnorderedMap<ComponentRef, list<ComponentRef>> seed_elements "base name -> element seeds";
      output list<ComponentRef> crefs = {cref};
    protected
      ComponentRef base;
      Type ty;
    algorithm
      if not List.all(ComponentRef.subscriptsAllFlat(cref), function sparsityIsOwnSubscript(own_iters = own_iters)) then
        base := ComponentRef.stripSubscriptsAll(cref);
        if UnorderedMap.contains(base, seed_elements) then
          crefs := UnorderedMap.getSafe(base, seed_elements, sourceInfo());
        else
          ty := ComponentRef.getSubscriptedType(base);
          crefs := if Type.isArray(ty) and Type.sizeOf(ty) <= 1024 then ComponentRef.scalarizeAll(base, false) else {base};
        end if;
      end if;
    end sparsityExpandForeignIterators;

    function sparsityIsOwnSubscript
      input Subscript sub;
      input UnorderedSet<ComponentRef> own_iters;
      output Boolean b = Subscript.isLiteral(sub) or Subscript.isWhole(sub) or Subscript.isSliced(sub)
        or UnorderedSet.all(Expression.extractCrefs(Subscript.toExp(sub)), function sparsityIsOwnCref(own_iters = own_iters));
    end sparsityIsOwnSubscript;

    function sparsityIsOwnCref
      "an iterator of this equation or a parameter (x[N])"
      input ComponentRef cref;
      input UnorderedSet<ComponentRef> own_iters;
      output Boolean b = UnorderedSet.contains(cref, own_iters) or not ComponentRef.isIterator(cref);
    end sparsityIsOwnCref;

    function sparsityAddInner
      "sliced inner variables are also added by their name, later equations might use other slices of them.
      entries are merged, several components can solve parts of the same variable"
      input ComponentRef cref;
      input list<ComponentRef> deps;
      input UnorderedMap<ComponentRef, list<ComponentRef>> inner_map;
      input UnorderedMap<ComponentRef, list<ComponentRef>> inner_keys "name -> the crefs its slices are solved as, once per component";
    protected
      ComponentRef stripped = ComponentRef.stripSubscriptsAll(cref);
    algorithm
      // several components can solve slices of the same variable with the same cref (e.g. x[$i1])
      UnorderedMap.add(cref, UnorderedSet.unique_list(listAppend(deps, UnorderedMap.getOrDefault(cref, inner_map, {})), ComponentRef.hash, ComponentRef.isEqual), inner_map);
      if not ComponentRef.isEqual(stripped, cref) then
        UnorderedMap.add(stripped, UnorderedSet.unique_list(listAppend(deps, UnorderedMap.getOrDefault(stripped, inner_map, {})), ComponentRef.hash, ComponentRef.isEqual), inner_map);
      end if;
      // every component that solves (a part of) the variable, also as a whole (e.g. an algebraic loop)
      UnorderedMap.add(stripped, cref :: UnorderedMap.getOrDefault(stripped, inner_keys, {}), inner_keys);
    end sparsityAddInner;

    function sparsityRemoveCovered
      "removes the dependencies of a row on elements (x[i]) that a dependency on all
      elements of the same variable (x) covers."
      input UnorderedMap<ComponentRef, Dependency> dep_map;
      input UnorderedSet<ComponentRef> rep_set;
    protected
      type Crefs = list<ComponentRef>;
      UnorderedMap<ComponentRef, Crefs> covering = UnorderedMap.new<Crefs>(ComponentRef.hash, ComponentRef.isEqual);
      ComponentRef cref, name;
      Dependency dep;
    algorithm
      for tpl in UnorderedMap.toList(dep_map) loop
        (cref, dep) := tpl;
        cref := ComponentRef.fillSubscripts(cref);
        if sparsityCoversAll(cref, dep, UnorderedSet.contains(Util.tuple21(tpl), rep_set)) then
          name := ComponentRef.stripSubscriptsAll(cref);
          UnorderedMap.add(name, cref :: UnorderedMap.getOrDefault(name, covering, {}), covering);
        end if;
      end for;
      if UnorderedMap.isEmpty(covering) then
        return;
      end if;
      for key in UnorderedMap.keyList(dep_map) loop
        cref := ComponentRef.fillSubscripts(key);
        if List.any(UnorderedMap.getOrDefault(ComponentRef.stripSubscriptsAll(cref), covering, {}), function sparsityCovers(cref = cref)) then
          UnorderedMap.remove(key, dep_map);
          UnorderedSet.remove(key, rep_set);
        end if;
      end for;
    end sparsityRemoveCovered;

    function sparsityCoversAll
      "a dependency with whole subscripts covers all their elements, except a regular
      dependency on a whole one-dimensional array, which code generation treats
      elementwise."
      input ComponentRef cref "with filled subscripts";
      input Dependency dep;
      input Boolean repeated;
      output Boolean b;
    protected
      list<Subscript> subs = ComponentRef.subscriptsAllFlat(cref);
    algorithm
      b := List.any(subs, Subscript.isWhole) and (repeated or listLength(subs) <> 1 or listEmpty(dep.kinds)
        or Dependency.isReductionKind(listHead(dep.kinds)));
    end sparsityCoversAll;

    function sparsityCovers
      input ComponentRef cover "with filled subscripts";
      input ComponentRef cref "with filled subscripts";
      output Boolean b;
    protected
      list<Subscript> cover_subs = ComponentRef.subscriptsAllFlat(cover);
      list<Subscript> subs = ComponentRef.subscriptsAllFlat(cref);
    algorithm
      b := not ComponentRef.isEqual(cover, cref) and listLength(cover_subs) == listLength(subs)
        and List.all(list(Subscript.isWhole(c) or Subscript.isEqual(c, s) threaded for c in cover_subs, s in subs), Util.id);
    end sparsityCovers;

    function upgrade
      "upgrades a matrix using the information provided by the full matrix"
      input output Matrix adj;
      input Matrix full;
      input UnorderedMap<ComponentRef, Integer> vars_map;
      input UnorderedMap<ComponentRef, Integer> eqns_map;
      input EquationPointers eqns;
      input MatrixStrictness st;
      input Iterator iter = Iterator.EMPTY();
    algorithm
      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print(StringUtil.headline_1("Upgrading from [" + strictnessString(getStrictness(adj)) + "] to [" + strictnessString(st) +"]") + "\n");
      end if;

      adj := match full
        local
          Integer min, max;
          IntMatrix.Builder builder;
          list<Integer> indices;

        case EMPTY() then EMPTY(st);

        case FULL() algorithm
          // empty matrices can have a strictness if we want to expand them, in this case ignore and overwrite
          // min is the rank the matrix already contains, -1 for an empty one
          if isEmpty(adj) then
            min := -1;
            adj := initialize(full.mapping, st);
          else
            min := Solvability.rank(Solvability.fromStrictness(getStrictness(adj)));
          end if;
          max := Solvability.rank(Solvability.fromStrictness(st));

          adj := match adj
            local
              Matrix result;
              list<ComponentRef> filtered;
              array<UnorderedSet<ComponentRef>> occ;
              array<UnorderedMap<ComponentRef, Dependency>> dep;
              array<UnorderedMap<ComponentRef, Solvability>> sol;
              array<UnorderedSet<ComponentRef>> rep;

            // default case
            case FINAL() algorithm
              // only do if valid upgrade otherwise create from scratch and issue warning if failtrace is activated
              if max == min then
                result := adj;
              elseif max > min then
                (occ, dep, sol, rep) := (full.occurrences, full.dependencies, full.solvabilities, full.repetitions);
                indices := UnorderedMap.valueList(eqns_map);
                builder := IntMatrix.toBuilder(adj.m, estimateEntries(occ, adj.mapping, indices, eqns), true);
                for index in indices loop
                  filtered := Solvability.filter(UnorderedSet.toList(occ[index]), sol[index], vars_map, min + 1, max);
                  // upgrade the row and all meta data
                  upgradeRow(EquationPointers.getEqnAt(eqns, index), index, filtered, dep[index], rep[index], vars_map, vars_map, builder, adj.mapping, adj.modes, iter);
                end for;
                adj.m  := IntMatrix.fromBuilder(builder, IntMatrix.rows(adj.m));
                adj.mT := IntMatrix.transpose(adj.m, arrayLength(adj.mapping.var_StA));
                result := adj;
              else
                if Flags.isSet(Flags.FAILTRACE) then
                  Error.addCompilerWarning("Invalid matrix upgrade request. Cannot upgrade matrix of type "
                    + Solvability.toString(Solvability.fromStrictness(getStrictness(adj))) + " to type "
                    + Solvability.toString(Solvability.fromStrictness(st)) + ". The new matrix will be
                    created from using only the full adjacency matrix.");
                end if;
                result := fullToFinal(full, vars_map, eqns_map, eqns, st, iter);
              end if;
            then result;

            // if its still empty even after initializing it, there are no variables or equations
            case EMPTY() then adj;

            // cannot upgrade a full matrix
            case FULL() algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong matrix type for the 1st input.
                Expected: final or empty, Got :" + strictnessString(getStrictness(adj)) + "."});
            then fail();
          end match;
        then adj;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of wrong matrix type for the 2nd input.
            Expected: full, Got :" + strictnessString(getStrictness(full)) + "."});
        then fail();
      end match;

      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print(toString(adj, "Final") + "\n");
      end if;
    end upgrade;

    function equalRows
      "equation index -> index of the equal equation in seed_eqns, 0 if none.
      Its rows in a final matrix over (seed_eqns, seed_vars) are its rows in one
      over (eqns, vars), so nothing is shared unless the variables are the same
      in the same order."
      input EquationPointers seed_eqns;
      input VariablePointers seed_vars;
      input EquationPointers eqns;
      input VariablePointers vars;
      output array<Integer> seed_index = arrayCreate(EquationPointers.lastUsedIndex(eqns), 0);
    protected
      Integer n = VariablePointers.size(vars), i;
      Pointer<Equation> seed_eqn;
    algorithm
      if n <> VariablePointers.size(seed_vars) or n <> VariablePointers.lastUsedIndex(vars) or n <> VariablePointers.lastUsedIndex(seed_vars) then return; end if;
      for j in 1:n loop
        if not referenceEq(VariablePointers.getVarAt(vars, j), VariablePointers.getVarAt(seed_vars, j)) then return; end if;
      end for;
      for eqn in EquationPointers.toList(eqns) loop
        i := EquationPointers.getEqnIndex(seed_eqns, Equation.getEqnName(eqn));
        if i > 0 then
          seed_eqn := EquationPointers.getEqnAt(seed_eqns, i);
          if Equation.isEqual(Pointer.access(eqn), Pointer.access(seed_eqn)) then
            seed_index[EquationPointers.getEqnIndex(eqns, Equation.getEqnName(eqn))] := i;
          end if;
        end if;
      end for;
    end equalRows;

    function upgradeFrom
      "upgrade, taking the rows of equations with a seed_index (see equalRows)
      from seed, a final matrix of strictness st that shares its variables"
      input output Matrix adj;
      input Matrix full;
      input UnorderedMap<ComponentRef, Integer> vars_map;
      input UnorderedMap<ComponentRef, Integer> eqns_map;
      input EquationPointers eqns;
      input MatrixStrictness st;
      input Matrix seed;
      input array<Integer> seed_index;
    protected
      Integer min, max, rows, eqn_start, eqn_size, seed_start, own_entries = 0, shared_entries = 0;
      Boolean fresh = isEmpty(adj);
      IntMatrix m, own_m;
      IntMatrix.Builder builder;
      list<Integer> own = {};
      list<ComponentRef> filtered;
      array<Integer> data, aux, seed_data, seed_aux, seen;
      IntMatrix.CopyMap seed_map, own_map;
    algorithm
      max := Solvability.rank(Solvability.fromStrictness(st));
      min := if fresh then -1 else Solvability.rank(Solvability.fromStrictness(getStrictness(adj)));
      adj := match (adj, full, seed)
        case (_, FULL(), FINAL()) guard(min < max) algorithm
          if fresh then
            adj := initialize(full.mapping, st);
          end if;
          adj := match adj
            case FINAL() algorithm
              if fresh then
                adj.modes := Vector.copy(seed.modes);
              end if;
              rows := IntMatrix.rows(adj.m);
              for index in UnorderedMap.valueList(eqns_map) loop
                (eqn_start, eqn_size) := adj.mapping.eqn_AtS[index];
                if seed_index[index] > 0 then
                  (seed_start, _) := seed.mapping.eqn_AtS[seed_index[index]];
                  for k in 0:eqn_size - 1 loop
                    shared_entries := shared_entries + IntMatrix.rowLength(seed.m, seed_start + k);
                  end for;
                else
                  own := index :: own;
                  own_entries := own_entries + estimateEntries(full.occurrences, adj.mapping, {index}, eqns);
                end if;
              end for;
              own := listReverse(own);

              // the own rows are built the way upgrade builds all rows
              builder := IntMatrix.newBuilder(own_entries, true);
              seen := arrayCreate(IntMatrix.storedCount(adj.m) + 1, 0);
              for index in own loop
                (eqn_start, eqn_size) := adj.mapping.eqn_AtS[index];
                for k in eqn_size - 1:-1:0 loop
                  IntMatrix.builderAddRowOf(builder, eqn_start + k, adj.m, eqn_start + k, seen);
                end for;
              end for;
              for index in own loop
                filtered := Solvability.filter(UnorderedSet.toList(full.occurrences[index]), full.solvabilities[index], vars_map, min + 1, max);
                upgradeRow(EquationPointers.getEqnAt(eqns, index), index, filtered, full.dependencies[index], full.repetitions[index], vars_map, vars_map, builder, adj.mapping, adj.modes);
              end for;
              own_m := IntMatrix.fromBuilder(builder, rows);

              m := IntMatrix.new(rows);
              IntMatrix.reserveData(m, intMin(shared_entries, IntMatrix.storedCount(seed.m)) + IntMatrix.storedCount(own_m), true);
              seed_map := IntMatrix.newCopyMap(seed.m);
              own_map := IntMatrix.newCopyMap(own_m);
              data := IntMatrix.entries(own_m);
              aux := IntMatrix.payload(own_m);
              seed_data := IntMatrix.entries(seed.m);
              seed_aux := IntMatrix.payload(seed.m);
              if arrayLength(seed_aux) == 0 then
                seed_aux := arrayCreate(arrayLength(seed_data), 0);
              end if;
              for index in UnorderedMap.valueList(eqns_map) loop
                (eqn_start, eqn_size) := adj.mapping.eqn_AtS[index];
                if seed_index[index] > 0 then
                  (seed_start, _) := seed.mapping.eqn_AtS[seed_index[index]];
                  for k in 0:eqn_size - 1 loop
                    IntMatrix.copyRow(seed.m, seed_start + k, seed_data, seed_aux, m, eqn_start + k, seed_map);
                  end for;
                else
                  for k in 0:eqn_size - 1 loop
                    IntMatrix.copyRow(own_m, eqn_start + k, data, aux, m, eqn_start + k, own_map);
                  end for;
                end if;
              end for;
              adj.m  := m;
              adj.mT := IntMatrix.transpose(m, arrayLength(adj.mapping.var_StA));
            then adj;
            else adj;
          end match;
        then adj;
        else upgrade(adj, full, vars_map, eqns_map, eqns, st);
      end match;
    end upgradeFrom;

    function expand
      "expands the adjacency matrix adj with new information provided by vn and en.
      If necessary it also expands the full matrix."
      input output Matrix adj                             "adjancency matrix to be expanded";
      input output Matrix full                            "full matrix having all information";
      input UnorderedMap<ComponentRef, Integer> vo, vn    "old and new variable index map";
      input UnorderedMap<ComponentRef, Integer> eo, en    "old and new equation index map";
      input VariablePointers vars                         "all variables, containing new and old";
      input EquationPointers eqns                         "all equations, containing new and old";
      input Partition.Kind kind;
    protected
      Integer size_vo, size_vn, size_eo, size_en; //only for debugging
    algorithm
      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        size_vo := sum(ComponentRef.size(var, true) for var in UnorderedMap.keyList(vo));
        size_vn := sum(ComponentRef.size(var, true) for var in UnorderedMap.keyList(vn)) + size_vo;
        size_eo := sum(ComponentRef.size(eqn, true) for eqn in UnorderedMap.keyList(eo));
        size_en := sum(ComponentRef.size(eqn, true) for eqn in UnorderedMap.keyList(en)) + size_eo;
        print(StringUtil.headline_1("Expanding from size [vars: " + intString(size_vo) + "| eqns: " + intString(size_eo) + "] to [vars: " + intString(size_vn) + "| eqns: " + intString(size_en) +  "]") + "\n");
      end if;

      // check if full has to be expanded
      full := match full
        case FULL() guard(EquationPointers.size(eqns) > arrayLength(full.equation_names))
          then expandFull(full, vo, vn, eo, en, vars, eqns, kind);
        else full;
      end match;

      adj := match (adj, full)
        local
          Matrix new;
          Integer rank, max_index_eq, max_index_var, eqn_scalar_size;
          list<ComponentRef> filtered;
          list<Integer> eo_lst, en_lst;
          IntMatrix.Builder builder;
          UnorderedMap<ComponentRef, Integer> v = vo;

        // if the matrix is empty, initialize it first
        case (EMPTY(), FULL()) algorithm
          new := initialize(full.mapping, adj.st);
          if not isEmpty(new) then
            new := expand(new, full, vo, vn, eo, en, vars, eqns, kind);
          end if;
        then new;

        // default case
        case (FINAL(), FULL()) algorithm
          // 0. expand the integer matrix
          eqn_scalar_size := EquationPointers.scalarSize(eqns, true);
          adj.mapping := full.mapping;
          eo_lst := UnorderedMap.valueList(eo);
          en_lst := UnorderedMap.valueList(en);
          builder := IntMatrix.toBuilder(adj.m,
            estimateEntries(full.occurrences, adj.mapping, eo_lst, eqns) + estimateEntries(full.occurrences, adj.mapping, en_lst, eqns), true);


          // get the strictness ranking
          rank := Solvability.rank(Solvability.fromStrictness(getStrictness(adj)));
          // only merge if there is a second phase
          if not UnorderedMap.isEmpty(vn) and not UnorderedMap.isEmpty(en) then
            v := UnorderedMap.merge(v, vn, sourceInfo());
          end if;

          // I. update all old equations with the new variables
          if not UnorderedMap.isEmpty(vn) then
            for e in eo_lst loop
              filtered := Solvability.filter(UnorderedSet.toList(full.occurrences[e]), full.solvabilities[e], vn, 0, rank);
              upgradeRow(EquationPointers.getEqnAt(eqns, e), e, filtered, full.dependencies[e], full.repetitions[e], vn, vars.map, builder, adj.mapping, adj.modes);
            end for;
          end if;

          // II. update new equations with all variables
          if not UnorderedMap.isEmpty(en) then
            for e in en_lst loop
              filtered := Solvability.filter(UnorderedSet.toList(full.occurrences[e]), full.solvabilities[e], v, 0, rank);
              upgradeRow(EquationPointers.getEqnAt(eqns, e), e, filtered, full.dependencies[e], full.repetitions[e], v, vars.map, builder, adj.mapping, adj.modes);
            end for;
          end if;

          // transpose the matrix
          if UnorderedMap.isEmpty(vo) and UnorderedMap.isEmpty(vn) then
            max_index_var := 0;
          else
            max_index_var := intMax(max(i for i in UnorderedMap.valueList(vo)), max(i for i in UnorderedMap.valueList(vn)));
          end if;
          adj.m  := IntMatrix.fromBuilder(builder, eqn_scalar_size);
          adj.mT := IntMatrix.transpose(adj.m, VariablePointers.scalarSize(vars, true));
        then adj;

        // fail cases
        case (FINAL(), _) algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the full matrix expected to contain all information is instead of type "
            + strictnessString(getStrictness(full)) + "."});
        then fail();

        case (_, FULL()) algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the matrix to be expanded of type "
            + strictnessString(getStrictness(adj)) + " should be of type final."});
        then fail();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " expected types final and full, got types " + strictnessString(getStrictness(adj))
            + " and " + strictnessString(getStrictness(full)) + "."});
        then fail();
      end match;

      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print(toString(adj, "Expanded Final") + "\n");
      end if;
    end expand;

    function expandFull
      "usually only called from expand()"
      input output Matrix full                            "full matrix having all information";
      input UnorderedMap<ComponentRef, Integer> vo, vn    "old and new variable index map";
      input UnorderedMap<ComponentRef, Integer> eo, en    "old and new equation index map";
      input VariablePointers vars                         "all variables, containing new and old";
      input EquationPointers eqns                         "all equations, containing new and old";
      input Partition.Kind kind;
    algorithm
      full := match full
        local
          list<Pointer<Variable>> new_vars = list(VariablePointers.getVarAt(vars, idx) for idx in UnorderedMap.valueList(vn));
          list<Pointer<Equation>> new_eqns = list(EquationPointers.getEqnAt(eqns, idx) for idx in UnorderedMap.valueList(en));
          Integer index, size = EquationPointers.size(eqns);
          Pointer<Equation> eqn_ptr;
          UnorderedSet<ComponentRef> occ_set;
        case FULL() algorithm
          // 0. enlargen the arrays
          full := FULL(Array.expandToSize(size, full.equation_names, ComponentRef.EMPTY()),
            Array.expandToSize(size, full.occurrences, UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual)),
            Array.expandToSize(size, full.dependencies, UnorderedMap.new<Dependency>(ComponentRef.hash, ComponentRef.isEqual)),
            Array.expandToSize(size, full.solvabilities, UnorderedMap.new<Solvability>(ComponentRef.hash, ComponentRef.isEqual)),
            Array.expandToSize(size, full.repetitions, UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual)),
            Mapping.expand(full.mapping, new_eqns, new_vars));

          // I. update all old equations with the new variables
          if not UnorderedMap.isEmpty(vn) then
            for e in UnorderedMap.valueList(eo) loop
              eqn_ptr := EquationPointers.getEqnAt(eqns, e);
              index   := UnorderedMap.getSafe(Equation.getEqnName(eqn_ptr), eqns.map, sourceInfo());
              occ_set := collectDependenciesEquation(Pointer.access(eqn_ptr), kind, vn, full.dependencies[index], full.solvabilities[index], full.repetitions[index]);
              full.occurrences[index] := UnorderedSet.union(full.occurrences[index], occ_set);
            end for;
          end if;

          // II. update new equations with all variables
          if not UnorderedMap.isEmpty(en) then
            for e in UnorderedMap.valueList(en) loop
              eqn_ptr := EquationPointers.getEqnAt(eqns, e);
              index   := UnorderedMap.getSafe(Equation.getEqnName(eqn_ptr), eqns.map, sourceInfo());
              occ_set := collectDependenciesEquation(Pointer.access(eqn_ptr), kind, vars.map, full.dependencies[index], full.solvabilities[index], full.repetitions[index]);
              full.equation_names[index] := Equation.getEqnName(eqn_ptr);
              full.occurrences[index] := occ_set;
            end for;
          end if;
        then full;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " expected type full, got type " + strictnessString(getStrictness(full)) + "."});
        then fail();
      end match;

      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print(toString(full, "Expanded Full") + "\n");
      end if;
    end expandFull;

    function containsLoopCref
      "true if the expression contains a cref of the set, also as an element of an array in the set"
      input Expression exp;
      input UnorderedSet<ComponentRef> set;
      output Boolean b = Expression.fold(exp, function isLoopCref(set = set), false);
    end containsLoopCref;

    function isLoopCref
      input Expression exp;
      input output Boolean b;
      input UnorderedSet<ComponentRef> set;
    algorithm
      b := match (b, exp)
        case (false, Expression.CREF())
          then UnorderedSet.contains(exp.cref, set) or UnorderedSet.contains(ComponentRef.stripSubscriptsAll(exp.cref), set);
        else b;
      end match;
    end isLoopCref;

    function refine
      "refines the solvability kind using differentiation
      Note: only updates the solvabilites of the variables and equations from the maps v and e"
      input output Matrix full;
      input UnorderedMap<Path, Function> funcMap;
      input UnorderedMap<ComponentRef, Integer> v    "variables to refine";
      input UnorderedMap<ComponentRef, Integer> e    "equations to refine";
      input VariablePointers vars                    "all variables";
      input EquationPointers eqns                    "all equations";
      input UnorderedSet<ComponentRef> vars_set      "context variables to determine solvability";
      input Boolean init                             "true if initial";
    algorithm
      full := match full
        local
          DifferentiationArguments diffArgs = DifferentiationArguments.default(NBDifferentiate.DifferentiationType.SIMPLE, funcMap);
          Pointer<Equation> eqn_ptr;
          Expression residual = Expression.EMPTY(Type.REAL()), exp;
          Solve.Status status;
          Solvability sol;
          UnorderedSet<ComponentRef> linear_set, param_set, var_set;
          Boolean eqnIsDiscrete, eqnIsIf, eqnHasNoResidual, diffOk;
          Option<Expression> residual_opt;

        case FULL() algorithm
          for eqn_idx in UnorderedMap.valueArray(e) loop
            eqn_ptr := EquationPointers.getEqnAt(eqns, eqn_idx);
            // ALGORITHM equations have no simple scalar residual for getResidualExp --
            // treat them like discrete equations (solveSimple fallback below) instead of
            // crashing, now that NBTearing.mo's initialize can pass them in here.
            eqnIsDiscrete := Equation.isDiscrete(eqn_ptr) or Equation.isWhenEquation(eqn_ptr) or Equation.isAlgorithm(eqn_ptr);
            eqnIsIf := Equation.isIfEquation(eqn_ptr);
            eqnHasNoResidual := false;
            if not (eqnIsDiscrete or eqnIsIf) then
              // e.g. a RECORD_EQUATION whose type has no '+'/'-'/'0' operators (a plain
              // Medium ThermodynamicState, for example) can't have a residual built at
              // all -- fall back to IMPLICIT below instead of crashing.
              residual_opt := Equation.tryGetResidualExp(eqn_ptr);
              if isSome(residual_opt) then
                SOME(residual) := residual_opt;
              else
                eqnHasNoResidual := true;
              end if;
            end if;
            for var in UnorderedSet.toArray(full.occurrences[eqn_idx]) loop
              // only do something if var is to be refined
              if UnorderedMap.contains(var, v) then
                // only do something if it is not implicit or unsolvable)
                sol := UnorderedMap.getSafe(var, full.solvabilities[eqn_idx], sourceInfo());
                if Solvability.rank(sol) < Solvability.rank(Solvability.IMPLICIT()) then
                  // booleans or (todo: enumerations)
                  if eqnIsDiscrete or not BVariable.checkCref(var, function BVariable.isContinuous(staticAsContinuous = init), sourceInfo()) then
                    // if the equation or cref type is boolean, it can only be solved if its isolated in the LHS or RHS
                    // Use solveSimple for this and check if status is EXPLICIT
                    (_, status, _) := Solve.solveSimple(Pointer.access(eqn_ptr), var);
                    sol := if status == NBSolve.Status.EXPLICIT then Solvability.EXPLICIT_LINEAR(NONE(), NONE()) else Solvability.UNSOLVABLE();
                  elseif eqnIsIf or eqnHasNoResidual then
                    // TODO more thorough analysis
                    sol := Solvability.IMPLICIT();
                  else
                    // get the residual expression, differentiate and simplify it
                    diffArgs.diffCref := var;
                    try
                      (exp, diffArgs) := Differentiate.differentiateExpressionDump(residual, diffArgs, getInstanceName());
                      exp             := SimplifyExp.simplifyDump(exp, true, getInstanceName());
                      diffOk          := true;
                    else
                      // not everything can be differentiated, e.g. functions with function inputs
                      exp             := residual;
                      diffOk          := false;
                    end try;
                    if not diffOk then
                      sol := Solvability.IMPLICIT();
                    elseif Expression.isZero(exp) then
                      sol := Solvability.UNSOLVABLE();
                    elseif containsLoopCref(exp, vars_set) then
                      // nonlinear -> unique solution if does not contain the variable itself
                      // TODO: might still be unique in some cases, even if contains the variable, e.g. `exp(x)`
                      sol := Solvability.EXPLICIT_NONLINEAR(not Expression.containsCref(exp, var));
                    else
                      // linear -> find all contained crefs and split them by kind. remove constants and save params / variables
                      linear_set  := Expression.extractCrefs(exp);
                      linear_set  := UnorderedSet.filterOnFalse(linear_set, function BVariable.checkCref(func = BVariable.isConst, info = sourceInfo()));
                      (param_set, var_set) := UnorderedSet.splitOnTrue(linear_set, function BVariable.checkCref(func = BVariable.isParamOrConst, info = sourceInfo()));
                      sol := Solvability.EXPLICIT_LINEAR(
                        pars = if UnorderedSet.isEmpty(param_set) then NONE() else SOME(param_set),
                        vars = if UnorderedSet.isEmpty(var_set) then NONE() else SOME(var_set));
                    end if;
                  end if;
                  UnorderedMap.add(var, sol, full.solvabilities[eqn_idx]);
                end if;
              end if;
            end for;
          end for;
        then full;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " expected type full, got type " + strictnessString(getStrictness(full)) + "."});
        then fail();
      end match;

      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print(toString(full, "Refined Full") + "\n");
      end if;
    end refine;

    function compress
      "use after equations have been removed"
      input output Matrix adj;
      input output Matrix full;
      input EquationPointers eqns;
      input VariablePointers vars;
      input UnorderedMap<ComponentRef, Integer> old_map;
    protected
      Integer index_old, index_new, size = EquationPointers.size(eqns);
      ComponentRef name;
      array<ComponentRef> equation_names;
      array<UnorderedSet<ComponentRef>> occurrences;
      array<UnorderedMap<ComponentRef, Dependency>> dependencies;
      array<UnorderedMap<ComponentRef, Solvability>> solvabilities;
      array<UnorderedSet<ComponentRef>> repetitions;
      Mapping mapping;
      IntMatrix m;
      array<Integer> m_data, m_aux;
      IntMatrix.CopyMap copy_map;
      Integer old_start, old_size, new_start, new_size;
    algorithm
      (adj, full) := match (adj, full)
        local
          Matrix new_adj, new_full;
        case (FINAL(), FULL()) algorithm
          // create the index mapping from scratch
          mapping := Mapping.create(eqns, vars);

          // create empty arrays for the structures
          m               := IntMatrix.new(arrayLength(mapping.eqn_StA));
          m_data          := IntMatrix.entries(adj.m);
          m_aux           := IntMatrix.payload(adj.m);
          copy_map        := IntMatrix.newCopyMap(adj.m);
          equation_names  := arrayCreate(size, ComponentRef.EMPTY());
          occurrences      := arrayCreate(size, UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual));
          dependencies    := arrayCreate(size, UnorderedMap.new<Dependency>(ComponentRef.hash, ComponentRef.isEqual));
          solvabilities   := arrayCreate(size, UnorderedMap.new<Solvability>(ComponentRef.hash, ComponentRef.isEqual));
          repetitions     := arrayCreate(size, UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual));
          // loop over each equation and copy the corresponding maps and sets
          for eqn_ptr in EquationPointers.toList(eqns) loop
            name        := Equation.getEqnName(eqn_ptr);
            index_new   := UnorderedMap.getSafe(name, eqns.map, sourceInfo());
            index_old   := UnorderedMap.getSafe(name, old_map, sourceInfo());
            // create structures for final matrix
            (old_start, old_size)     := adj.mapping.eqn_AtS[index_old];
            (new_start, new_size)     := mapping.eqn_AtS[index_new];
            if old_size == new_size then
              for i in 0:old_size-1 loop
                IntMatrix.copyRow(adj.m, old_start+i, m_data, m_aux, m, new_start+i, copy_map);
              end for;
            else
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " sizes (old: " + intString(old_size) + ", new: "
                + intString(new_size) + " do not mach for equation:\n" + Equation.pointerToString(eqn_ptr)});
              fail();
            end if;
            // create the structures for full matrix
            equation_names[index_new] := name;
            occurrences[index_new]     := full.occurrences[index_old];
            dependencies[index_new]   := full.dependencies[index_old];
            solvabilities[index_new]  := full.solvabilities[index_old];
            repetitions[index_new]    := full.repetitions[index_old];
          end for;

          new_adj  := FINAL(m, IntMatrix.transpose(m, VariablePointers.scalarSize(vars, true)), mapping, adj.modes, adj.st);
          new_full := FULL(equation_names, occurrences, dependencies, solvabilities, repetitions, mapping);
        then (new_adj, new_full);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " expected types final and full, got types " + strictnessString(getStrictness(adj))
            + " and " + strictnessString(getStrictness(full)) + "."});
        then fail();
      end match;

      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print(toString(adj, "Compressed Final") + "\n");
        print(toString(full, "Compressed Full") + "\n");
      end if;
    end compress;

    function combine
      "for now only combines sparsity matrices as its the only one needed"
      input list<Matrix> matrices;
      output Matrix result;
    protected
      list<list<ComponentRef>> equation_names = {};
      list<list<Iterator>> equation_iterators = {};
      list<list<UnorderedMap<ComponentRef, Dependency>>> dependencies = {};
      list<list<UnorderedSet<ComponentRef>>> repetitions = {};
      list<list<list<ComponentRef>>> solved_crefs = {};
    algorithm
      for matrix in listReverse(matrices) loop
        _ := match matrix
          case SPARSITY() algorithm
            equation_names      := arrayList(matrix.equation_names) :: equation_names;
            equation_iterators  := arrayList(matrix.equation_iterators) :: equation_iterators;
            dependencies        := arrayList(matrix.dependencies) :: dependencies;
            repetitions         := arrayList(matrix.repetitions) :: repetitions;
            solved_crefs        := arrayList(matrix.solved_crefs) :: solved_crefs;
          then ();

          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " expected type sparsity, got type " + strictnessString(getStrictness(matrix)) + "."});
          then fail();
        end match;
      end for;

      // compile the final result
      result := SPARSITY(
        equation_names      = listArray(List.flatten(equation_names)),
        equation_iterators  = listArray(List.flatten(equation_iterators)),
        dependencies        = listArray(List.flatten(dependencies)),
        repetitions         = listArray(List.flatten(repetitions)),
        solved_crefs        = listArray(List.flatten(solved_crefs))
      );
    end combine;

    function toString
      input Matrix adj;
      input output String str = "";
    algorithm
      str := match adj
        local
          list<Type> types;
          array<String> solved, names, types_str, complex_sizes;
          Integer length0, length1, length2, length3;

        case FULL() algorithm
          str := StringUtil.headline_2(str + "FULL Adjacency Matrix") + "\n";
          types := list(ComponentRef.getSubscriptedType(name) for name in adj.equation_names);
          complex_sizes := listArray(list(Util.applyOptionOrDefault(Type.complexSize(ty, true), intString, "0") for ty in types));
          types_str := listArray(list(dimsString(Type.arrayDims(ty)) for ty in types));
          names := listArray(list(ComponentRef.toString(name) for name in adj.equation_names));
          length0 := max(stringLength(sz) for sz in complex_sizes);
          length1 := max(stringLength(ty) for ty in types_str) + 1;
          length2 := max(stringLength(name) for name in names) + 3;
          for i in 1:arrayLength(names) loop
            str := str
              + arrayGet(complex_sizes, i) + " " + StringUtil.repeat(" ", length0 - stringLength(arrayGet(complex_sizes, i))) + " | "
              + arrayGet(types_str, i) + " " + StringUtil.repeat(".", length1 - stringLength(arrayGet(types_str, i)))
              + arrayGet(names, i) + " " + StringUtil.repeat(".", length2 - stringLength(arrayGet(names, i)))
              + " " + List.toString(UnorderedSet.toList(adj.occurrences[i]), function fullString(dep_map = adj.dependencies[i],
              sol_map = adj.solvabilities[i], rep_set = adj.repetitions[i])) + "\n";
          end for;
        then str;

        case FINAL() algorithm
          str := StringUtil.headline_2(str + "FINAL Adjacency Matrix") + "\n";
          if IntMatrix.rows(adj.m) > 0 then
            str := str + StringUtil.headline_4("Normal Adjacency Matrix (row = equation)");
            str := str + IntMatrix.toString(adj.m);
          end if;
          str := str + "\n";
          if IntMatrix.rows(adj.mT) > 0 then
            str := str + StringUtil.headline_4("Transposed Adjacency Matrix (row = variable)");
            str := str + IntMatrix.toString(adj.mT);
          end if;
          str := str + "\n" + Mapping.toString(adj.mapping);
        then str;

        case SPARSITY() algorithm
          str := StringUtil.headline_2(str + "SPARSITY Adjacency Matrix") + "\n";
          types := list(ComponentRef.getSubscriptedType(name) for name in adj.equation_names);
          complex_sizes := listArray(list(Util.applyOptionOrDefault(Type.complexSize(ty, true), intString, "0") for ty in types));
          types_str := listArray(list(dimsString(Type.arrayDims(ty)) for ty in types));
          names := listArray(list(ComponentRef.toString(name) for name in adj.equation_names));
          solved := listArray(list(List.toString(var_list, ComponentRef.toString) for var_list in adj.solved_crefs));
          length0 := max(stringLength(sz) for sz in complex_sizes);
          length1 := max(stringLength(ty) for ty in types_str) + 1;
          length2 := max(stringLength(name) for name in names) + 3;
          length3 := max(stringLength(var) for var in solved) + 3;
          for i in 1:arrayLength(names) loop
            str := str
              + arrayGet(complex_sizes, i) + " " + StringUtil.repeat(" ", length0 - stringLength(arrayGet(complex_sizes, i))) + " | "
              + arrayGet(types_str, i) + " " + StringUtil.repeat(".", length1 - stringLength(arrayGet(types_str, i)))
              + arrayGet(names, i) + " " + StringUtil.repeat(".", length2 - stringLength(arrayGet(names, i)))
              + arrayGet(solved, i) + " " + StringUtil.repeat(".", length3 - stringLength(arrayGet(solved, i)))
              + " " + List.toString(UnorderedMap.keyList(adj.dependencies[i]), function sparsityString(dep_map = adj.dependencies[i],
              rep_set = adj.repetitions[i])) + "\n";
          end for;
        then str;

        case EMPTY() then str + StringUtil.headline_4("EMPTY Adjacency Matrix") + "\n";
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown adjacency matrix type."});
        then fail();
      end match;
    end toString;

    function solvabilityString
      input Matrix adj;
      input output String str = "";
    algorithm
      str := match adj
        local
          list<ComponentRef> XX, II, NM, NP, LV, LP, LC, QQ;
          list<String> xx = {}, ii = {}, nm = {}, np = {}, lv = {}, lp = {}, lc = {}, qq = {};
          array<String> names, types, XX_, II_, NM_, NP_, LV_, LP_, LC_, QQ_;
          Integer length1, length2, length_xx, length_ii, length_nm, length_np, length_lv, length_lp, length_lc, length_qq;

        case FULL() algorithm
          str := StringUtil.headline_2(str + " Solvability Adjacency Matrix") + "\n";
          types := listArray(list(intString(Type.sizeOf(ComponentRef.getSubscriptedType(name), true)) for name in adj.equation_names));
          names := listArray(list(ComponentRef.toString(name) for name in adj.equation_names));
          for i in arrayLength(names):-1:1 loop
            (XX, II, NM, NP, LV, LP, LC, QQ) := Solvability.categorize(UnorderedSet.toList(adj.occurrences[i]), adj.solvabilities[i]);
            xx := List.toStringCustom(XX, ComponentRef.toString, "XX ", "{", ",", "}", false) :: xx;
            ii := List.toStringCustom(II, ComponentRef.toString, "II ", "{", ",", "}", false) :: ii;
            nm := List.toStringCustom(NM, ComponentRef.toString, "N- ", "{", ",", "}", false) :: nm;
            np := List.toStringCustom(NP, ComponentRef.toString, "N+ ", "{", ",", "}", false) :: np;
            lv := List.toStringCustom(LV, ComponentRef.toString, "LV ", "{", ",", "}", false) :: lv;
            lp := List.toStringCustom(LP, ComponentRef.toString, "LP ", "{", ",", "}", false) :: lp;
            lc := List.toStringCustom(LC, ComponentRef.toString, "LC ", "{", ",", "}", false) :: lc;
            qq := List.toStringCustom(QQ, ComponentRef.toString, "|| ", "{", ",", "}", false) :: qq;
          end for;
          XX_ := listArray(xx);
          II_ := listArray(ii);
          NM_ := listArray(nm);
          NP_ := listArray(np);
          LV_ := listArray(lv);
          LP_ := listArray(lp);
          LC_ := listArray(lc);
          QQ_ := listArray(qq);
          length1 := max(stringLength(ty) for ty in types) + 1;
          length2 := max(stringLength(name) for name in names) + 3;
          length_xx := max(stringLength(s) for s in XX_);
          length_ii := max(stringLength(s) for s in II_);
          length_nm := max(stringLength(s) for s in NM_);
          length_np := max(stringLength(s) for s in NP_);
          length_lv := max(stringLength(s) for s in LV_);
          length_lp := max(stringLength(s) for s in LP_);
          length_lc := max(stringLength(s) for s in LC_);
          length_qq := max(stringLength(s) for s in QQ_);
          for i in 1:arrayLength(names) loop
            str := str + arrayGet(types, i) + " " + StringUtil.repeat(".", length1 - stringLength(arrayGet(types, i))) + " "
              + arrayGet(names, i) + " " + StringUtil.repeat(".", length2 - stringLength(arrayGet(names, i)))
              + arrayGet(LC_, i) + " " + StringUtil.repeat(".", length_lc - stringLength(arrayGet(LC_, i)))
              + arrayGet(LP_, i) + " " + StringUtil.repeat(".", length_lp - stringLength(arrayGet(LP_, i)))
              + arrayGet(LV_, i) + " " + StringUtil.repeat(".", length_lv - stringLength(arrayGet(LV_, i)))
              + arrayGet(NP_, i) + " " + StringUtil.repeat(".", length_np - stringLength(arrayGet(NP_, i)))
              + arrayGet(NM_, i) + " " + StringUtil.repeat(".", length_nm - stringLength(arrayGet(NM_, i)))
              + arrayGet(II_, i) + " " + StringUtil.repeat(".", length_ii - stringLength(arrayGet(II_, i)))
              + arrayGet(XX_, i) + " " + StringUtil.repeat(".", length_xx - stringLength(arrayGet(XX_, i)))
              + arrayGet(QQ_, i) + " " + StringUtil.repeat(".", length_qq - stringLength(arrayGet(QQ_, i))) + "\n";
          end for;
        then str;
        else toString(adj, str);
      end match;
    end solvabilityString;

    function dependencyString
      input Matrix adj;
      input output String str = "";
    algorithm
      str := match adj
        local
          list<ComponentRef> F, R, E, A, S, K;
          list<String> f = {}, r = {}, e = {}, a = {}, s = {}, k = {};
          array<String> names, types, F_, R_, E_, A_, S_, K_;
          Integer length1, length2, lengthf, lengthr, lengthe, lengtha, lengths, lengthk;

        case FULL() algorithm
          str := StringUtil.headline_2(str + " Dependency Adjacency Matrix") + "\n";
          types := listArray(list(intString(Type.sizeOf(ComponentRef.getSubscriptedType(name), true)) for name in adj.equation_names));
          names := listArray(list(ComponentRef.toString(name) for name in adj.equation_names));
          for i in arrayLength(names):-1:1 loop
            (F, R, E, A, S, K) := Dependency.categorize(UnorderedSet.toList(adj.occurrences[i]), adj.dependencies[i], adj.repetitions[i]);
            f := List.toStringCustom(F, ComponentRef.toString, "[!]", "{", ",", "}", false) :: f;
            r := List.toStringCustom(R, ComponentRef.toString, "[-]", "{", ",", "}", false) :: r;
            e := List.toStringCustom(E, ComponentRef.toString, "[+]", "{", ",", "}", false) :: e;
            a := List.toStringCustom(A, ComponentRef.toString, "[:]", "{", ",", "}", false) :: a;
            s := List.toStringCustom(S, ComponentRef.toString, "[.]", "{", ",", "}", false) :: s;
            k := List.toStringCustom(K, ComponentRef.toString, "[o]", "{", ",", "}", false) :: k;
          end for;
          F_ := listArray(f);
          R_ := listArray(r);
          E_ := listArray(e);
          A_ := listArray(a);
          S_ := listArray(s);
          K_ := listArray(k);
          length1 := max(stringLength(ty) for ty in types) + 1;
          length2 := max(stringLength(name) for name in names) + 3;
          lengthf := max(stringLength(st) for st in F_);
          lengthr := max(stringLength(st) for st in R_);
          lengthe := max(stringLength(st) for st in E_);
          lengtha := max(stringLength(st) for st in A_);
          lengths := max(stringLength(st) for st in S_);
          lengthk := max(stringLength(st) for st in K_);
          for i in 1:arrayLength(names) loop
            str := str + arrayGet(types, i) + " " + StringUtil.repeat(".", length1 - stringLength(arrayGet(types, i))) + " "
              + arrayGet(names, i) + " " + StringUtil.repeat(".", length2 - stringLength(arrayGet(names, i)))
              + arrayGet(K_, i) + " " + StringUtil.repeat(".", lengthk - stringLength(arrayGet(K_, i)))
              + arrayGet(S_, i) + " " + StringUtil.repeat(".", lengths - stringLength(arrayGet(S_, i)))
              + arrayGet(A_, i) + " " + StringUtil.repeat(".", lengtha - stringLength(arrayGet(A_, i)))
              + arrayGet(E_, i) + " " + StringUtil.repeat(".", lengthe - stringLength(arrayGet(E_, i)))
              + arrayGet(R_, i) + " " + StringUtil.repeat(".", lengthr - stringLength(arrayGet(R_, i)))
              + arrayGet(F_, i) + " " + StringUtil.repeat(".", lengthf - stringLength(arrayGet(F_, i))) + "\n";
          end for;
        then str;
        else toString(adj, str);
      end match;
    end dependencyString;

    function getStrictness
      input Matrix adj;
      output MatrixStrictness st;
    algorithm
      st := match adj
        case FULL() then MatrixStrictness.FULL;
        case FINAL() then adj.st;
        case EMPTY() then adj.st;
        else fail();
      end match;
    end getStrictness;

    function isEmpty
      input Matrix adj;
      output Boolean b;
    algorithm
      b := match adj
        case EMPTY() then true;
        else              false;
      end match;
    end isEmpty;

    function getMappingOpt
      input Matrix adj;
      output Option<Mapping> mapping;
    algorithm
      mapping := match adj
        case FULL()  then SOME(adj.mapping);
        case FINAL() then SOME(adj.mapping);
        else NONE();
      end match;
    end getMappingOpt;

    function nonZeroCount
      input Matrix adj;
      output Integer count;
    algorithm
      count := match adj
        case FINAL()  then IntMatrix.nonZeroCount(adj.m);
        case EMPTY()         then 0;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown matrix type."});
        then fail();
      end match;
    end nonZeroCount;

  protected
    function fullString
      input ComponentRef cref;
      input UnorderedMap<ComponentRef, Dependency> dep_map;
      input UnorderedMap<ComponentRef, Solvability> sol_map;
      input UnorderedSet<ComponentRef> rep_set;
      output String str = ComponentRef.toString(cref) + "[";
    algorithm
      str := str + Solvability.toString(UnorderedMap.getSafe(cref, sol_map, sourceInfo()))
        + "|" + Dependency.toString(UnorderedMap.getSafe(cref, dep_map, sourceInfo()));
      if UnorderedSet.contains(cref, rep_set) then str := str + "+"; end if;
      str := str + "]";
    end fullString;

    function sparsityString
      input ComponentRef cref;
      input UnorderedMap<ComponentRef, Dependency> dep_map;
      input UnorderedSet<ComponentRef> rep_set;
      output String str = ComponentRef.toString(cref) + "[";
    algorithm
      str := str + Dependency.toString(UnorderedMap.getSafe(cref, dep_map, sourceInfo()));
      if UnorderedSet.contains(cref, rep_set) then str := str + "+"; end if;
      str := str + "]";
    end sparsityString;

    function dimsString
      input list<Dimension> dims;
      output String str;
    algorithm
      str := match dims
        case {} then "{1}";
        else List.toString(list(Dimension.size(d, true) for d in dims), intString);
      end match;
    end dimsString;

    function initialize
      input Mapping mapping;
      input MatrixStrictness st;
      output Matrix adj;
    protected
      Integer eqn_scalar_size, var_scalar_size;
    algorithm
      eqn_scalar_size := arrayLength(mapping.eqn_StA);
      var_scalar_size := arrayLength(mapping.var_StA);
      if eqn_scalar_size > 0 or var_scalar_size > 0 then
        adj := FINAL(IntMatrix.new(eqn_scalar_size), IntMatrix.new(var_scalar_size), mapping, Modes.new(), st);
      else
        adj := EMPTY(st);
      end if;
    end initialize;

    function estimateEntries
      "estimates how many entries the given equations contribute, to size the builder.
      equations with full dependency (see upgradeRow) add one shared section instead."
      input array<UnorderedSet<ComponentRef>> occ;
      input Mapping mapping;
      input list<Integer> indices;
      input EquationPointers eqns;
      output Integer n = 0;
    protected
      Integer sz;
      Pointer<Equation> eqn_ptr;
    algorithm
      for i in indices loop
        eqn_ptr := EquationPointers.getEqnAt(eqns, i);
        if not isFullDependency(eqn_ptr) then
          (_, sz) := mapping.eqn_AtS[i];
          n := n + UnorderedSet.size(occ[i]) * sz;
        end if;
      end for;
    end estimateEntries;

    function isFullDependency
      "every scalar row of the equation depends on all its variables (algorithms, if-equations)"
      input Pointer<Equation> eqn_ptr;
      output Boolean b = Equation.isAlgorithm(eqn_ptr) or Equation.isIfEquation(eqn_ptr);
    end isFullDependency;

    function upgradeRow
      input Pointer<Equation> eqn_ptr;
      input Integer eqn_arr_idx;
      input list<ComponentRef> dependencies             "dependent var crefs";
      input UnorderedMap<ComponentRef, Dependency> dep  "dependency map";
      input UnorderedSet<ComponentRef> rep              "repetition set";
      input UnorderedMap<ComponentRef, Integer> map     "unordered map to check for relevance";
      input UnorderedMap<ComponentRef, Integer> fullmap "unordered map to check for general relevance";
      input IntMatrix.Builder m;
      input Mapping mapping;
      input ModeTable modes;
      input Iterator iter_ = Iterator.EMPTY();
    protected
      Integer eqn_scal_idx, eqn_size, section;
      list<Integer> row;
      Equation eqn = Pointer.access(eqn_ptr);
      Iterator iter = Equation.getForIterator(eqn);
      Type ty = Equation.getType(eqn, true);
      list<ComponentRef> names;
      list<Expression> ranges;
      list<Option<Iterator>> maps;
    algorithm
      try
        // don't do this for if equations as soon as we properly split them
        if isFullDependency(eqn_ptr) then
          // algorithm full dependency: all scalar rows share one section
          (eqn_scal_idx, eqn_size) := mapping.eqn_AtS[eqn_arr_idx];
          row := Slice.upgradeRowFull(dependencies, map, mapping);
          if not listEmpty(row) then
            section := IntMatrix.builderSection(m, row);
            for i in 0:eqn_size-1 loop
              IntMatrix.builderAddSection(m, eqn_scal_idx+i, section);
            end for;
          end if;
        else
          // todo: if, when single equation (needs to be updated for if)

          // add the optional surrounding iterator frames
          if not Iterator.isEmpty(iter_) then
            (names, ranges, maps) := Iterator.getFrames(iter_);
            iter := Iterator.addFrames(iter, List.zip3(names, ranges, maps));
          end if;

          Slice.upgradeRow(Equation.getEqnName(eqn_ptr), eqn_arr_idx, iter, ty, dependencies, dep, rep, map, fullmap, m, mapping, modes);
        end if;
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n" + Equation.pointerToString(eqn_ptr)});
        fail();
      end try;
    end upgradeRow;

  end Matrix;

  uniontype Dependency
    "the dependency kind to show how a component reference occurs in an equation.
    for each dimension there has to be one dependency kind."
    type Kind = enumeration(REGULAR, REDUCTION);

    record DEPENDENCY
      array<list<Integer>> skips;
      list<Dependency.Kind> kinds;
    end DEPENDENCY;

    function toString
      input Dependency dep;
      output String str;
    protected
      function kindString
        input Kind kind;
        output String str;
      algorithm
        str := match kind
          case Kind.REGULAR then ":";
                            else "-";
        end match;
      end kindString;
      String str1, str2;
    algorithm
      str1 := Array.toString(dep.skips, function List.toString(
        inPrintFunc = intString, style = List.Style.FLAT_CURLY), "", "", ", ", "");
      str2 := List.toString(dep.kinds, kindString, List.Style.FLAT);
      str := if str1 == "" or str2 == "" then str1 + str2 else str1 + ", " + str2;
      str := "{" + str + "}";
    end toString;

    function toBoolean
      "converts the regular/reduction part of the dependency to a boolean list for scalarization"
      input Dependency dep;
      output list<Boolean> b = list(not isReductionKind(k) for k in dep.kinds);
    end toBoolean;

    function create
      input Type sub_ty;
      input Integer depth;
      output Dependency dep;
    algorithm
      dep := DEPENDENCY(arrayCreate(depth, {}), list(Kind.REGULAR for dim guard(not Dimension.isOne(dim)) in Type.arrayDims(sub_ty)));
    end create;

    function update
      "sets the dependency of num dimensions
      REGULAR -> REDUCTION"
      input ComponentRef cref;
      input Integer num     "number of dependencies to turn to reductions. negative means all";
      input Boolean reverse "true = from right, false = from left";
      input UnorderedMap<ComponentRef, Dependency> map;
    protected
      Option<Dependency> opt_dep = UnorderedMap.get(cref, map);
      Dependency dep;
      list<Kind> kinds;
      Integer res;

      function makeNewKinds
        input output list<Kind> kinds;
        input output Integer num;
      algorithm
        (kinds, num) := match (kinds, num)
          local
            list<Kind> rest;
          case (_, 0) then (kinds, num);
          case (_::rest, _) algorithm
            (kinds, num) := makeNewKinds(rest, num-1);
          then (Kind.REDUCTION :: kinds, num);
          else (kinds, num);
        end match;
      end makeNewKinds;
    algorithm
      if isSome(opt_dep) then
        SOME(dep) := opt_dep;

        // turn to reductions
        if reverse then
          (kinds, res) := makeNewKinds(listReverse(dep.kinds), num);
          dep.kinds := listReverse(kinds);
        else
          (kinds, res) := makeNewKinds(dep.kinds, num);
          dep.kinds := kinds;
        end if;

        // if any remain, remove from skips
        if res > 0 then
          removeSkips(cref, map, res, reverse);
        end if;

        // add the updated dependency back to the map
        UnorderedMap.add(cref, dep, map);
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because cref "
         + ComponentRef.toString(cref) + " was not found in the map."});
        fail();
      end if;
    end update;

    function skip
      input ComponentRef cref;
      input Integer depth;
      input Integer sk;
      input UnorderedMap<ComponentRef, Dependency> map;
    protected
      Option<Dependency> opt_dep = UnorderedMap.get(cref, map);
      Dependency dep;
    algorithm
      if isSome(opt_dep) then
        SOME(dep) := opt_dep;
        if arrayLength(dep.skips) >= depth then
          // this might scale badly, try to unique the lists in the end or always use sets here
          arrayUpdate(dep.skips, depth, UnorderedSet.unique_list(sk :: dep.skips[depth], Util.id, intEq));
        else
          if Flags.isSet(Flags.FAILTRACE) then
            Error.addCompilerWarning(getInstanceName() + ": Cref " + ComponentRef.toString(cref)
            + " was saved with depth " + intString(arrayLength(dep.skips)) + " but depth " + intString(depth) + " was requested.");
          end if;
        end if;

        UnorderedMap.add(cref, dep, map);
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because cref "
         + ComponentRef.toString(cref) + " was not found in the map."});
        fail();
      end if;
    end skip;

    function removeSkips
      input ComponentRef cref;
      input UnorderedMap<ComponentRef, Dependency> map;
      input Integer num = -1        "number of skips to remove. negative implys all";
      input Boolean reverse = false "if num > 0 this removes true->from right, false->from left";
    protected
      Option<Dependency> opt_dep = UnorderedMap.get(cref, map);
      Dependency dep;
      Integer rest = num;
      Integer i, len;
    algorithm
      if isSome(opt_dep) then
        SOME(dep) := opt_dep;
        if num < 0 then
          // remove all skips
          for i in 1:arrayLength(dep.skips) loop
            arrayUpdate(dep.skips, i, {});
          end for;
        else
          // remove specific number
          i := if reverse then arrayLength(dep.skips) else 1;
          while rest > 0 and i > 0 and i < arrayLength(dep.skips)+1 loop
            len := listLength(dep.skips[i]);
            if len <= rest then
              // can remove full list
              arrayUpdate(dep.skips, i, {});
            elseif len > 0 then
              // list needs to be reduced
              if reverse then
                arrayUpdate(dep.skips, i, List.firstN(dep.skips[i], len - rest));
              else
                arrayUpdate(dep.skips, i, List.lastN(dep.skips[i], len - rest));
              end if;
            end if;
            // update rest to remove and move iterator
            rest := rest - len;
            i := if reverse then i - 1 else i + 1;
          end while;
        end if;
        UnorderedMap.add(cref, dep, map);
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because cref "
         + ComponentRef.toString(cref) + " was not found in the map."});
        fail();
      end if;
    end removeSkips;

    function updateList
      input list<ComponentRef> lst;
      input Integer num;
      input Boolean reverse;
      input UnorderedMap<ComponentRef, Dependency> map;
    algorithm
      for cref in lst loop
        update(cref, num, reverse, map);
      end for;
    end updateList;

    function skipList
      input list<ComponentRef> lst;
      input Integer depth;
      input Integer sk;
      input UnorderedMap<ComponentRef, Dependency> map;
    algorithm
      for cref in lst loop
        skip(cref, depth, sk, map);
      end for;
    end skipList;

    function removeSkipsList
      input list<ComponentRef> lst;
      input UnorderedMap<ComponentRef, Dependency> map;
    algorithm
      for cref in lst loop
        removeSkips(cref, map);
      end for;
    end removeSkipsList;

    function addListFull
      "adds a list and applies full dependency"
      input list<ComponentRef> lst;
      input Integer depth;
      input UnorderedMap<ComponentRef, Dependency> map;
      input UnorderedSet<ComponentRef> rep;
    protected
      Dependency dep;
    algorithm
      for cref in lst loop
        UnorderedMap.add(cref, create(ComponentRef.getSubscriptedType(cref), depth), map);
        UnorderedSet.add(cref, rep);
      end for;
      updateList(lst, -1, false, map);
    end addListFull;

    function isReductionKind
      input Dependency.Kind kind;
      output Boolean b = kind == Kind.REDUCTION;
    end isReductionKind;

    function categorize
      input list<ComponentRef> crefs;
      input UnorderedMap<ComponentRef, Dependency> map;
      input UnorderedSet<ComponentRef> rep_set;
      output list<ComponentRef> F = {};
      output list<ComponentRef> R = {};
      output list<ComponentRef> E = {};
      output list<ComponentRef> A = {};
      output list<ComponentRef> S = {};
      output list<ComponentRef> K = {};
    protected
      Boolean repeats;
    algorithm
      for cref in crefs loop
        repeats := UnorderedSet.contains(cref, rep_set);
        _ := match UnorderedMap.getSafe(cref, map, sourceInfo())
          local
            array<list<Integer>> skips;
            list<Kind> kinds;
          case DEPENDENCY(skips = skips) guard(not Array.all(skips, listEmpty))
            algorithm K := cref :: K; then ();
          case DEPENDENCY(kinds = {}) guard(repeats)
            algorithm E := cref :: E; then ();
          case DEPENDENCY(kinds = {})
            algorithm S := cref :: S; then ();
          case DEPENDENCY(kinds = kinds) algorithm
            if List.any(kinds, isReductionKind) then
              if repeats then
                F := cref :: F;
              else
                R := cref :: R;
              end if;
            else
              A := cref :: A;
            end if;
          then ();
          else ();
        end match;
      end for;
    end categorize;

    function convert
      input Dependency dep;
      output OldSimCode.Dependency odep;
    protected
      function convertKind
        input Kind kind;
        output Boolean okind = kind == Kind.REDUCTION;
      end convertKind;
    algorithm
      odep := OldSimCode.DEPENDENCY(dep.skips, list(convertKind(kind) for kind in dep.kinds));
    end convert;
  end Dependency;

  uniontype Solvability
    record UNKNOWN end UNKNOWN; // do not set, only used as default if unset
    record UNSOLVABLE end UNSOLVABLE;
    record IMPLICIT end IMPLICIT;

    record EXPLICIT_NONLINEAR
      Boolean unique "true if it has a unique solution when solved";
    end EXPLICIT_NONLINEAR;

    record EXPLICIT_LINEAR
      Option<UnorderedSet<ComponentRef>> pars "parameters we need to divide by to solve";
      Option<UnorderedSet<ComponentRef>> vars "variables we need to divide by to solve";
    end EXPLICIT_LINEAR;

    function toString
      input Solvability sol;
      output String str;
    algorithm
      str := match sol
        case UNSOLVABLE()         then "XX";
        case IMPLICIT()           then "II";
        case EXPLICIT_NONLINEAR() then "N" + (if sol.unique then "+" else "-");
        case EXPLICIT_LINEAR()    then "L" + (if isSome(sol.vars) then "V" elseif isSome(sol.pars) then "P" else "C");
        case UNKNOWN()            then "||";
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown solvability kind."});
        then fail();
      end match;
    end toString;

    function rank
      input Solvability sol;
      output Integer r;
    algorithm
      r := match sol
        case UNSOLVABLE()                         then 7;
        case IMPLICIT()                           then 6;
        case EXPLICIT_NONLINEAR(unique = false)   then 5;
        case EXPLICIT_NONLINEAR()                 then 4;
        case EXPLICIT_LINEAR(vars = SOME(_))      then 3;
        case EXPLICIT_LINEAR(pars = SOME(_))      then 2;
        case EXPLICIT_LINEAR()                    then 1;
        case UNKNOWN()                            then 0;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown solvability kind."});
        then fail();
      end match;
    end rank;

    function update
      "sets the solvability of a component reference if it is of
      higher rank than previously determined"
      input ComponentRef cref;
      input Solvability sol;
      input UnorderedMap<ComponentRef, Solvability> map;
    algorithm
      if rank(sol) > rank(Util.getOptionOrDefault(UnorderedMap.get(cref, map), UNKNOWN())) then
        UnorderedMap.add(cref, sol, map);
      end if;
    end update;

    function updateList
      input list<ComponentRef> lst;
      input Solvability sol;
      input UnorderedMap<ComponentRef, Solvability> map;
    algorithm
      for cref in lst loop
        Solvability.update(cref, sol, map);
      end for;
    end updateList;

    function categorize
      input list<ComponentRef> crefs;
      input UnorderedMap<ComponentRef, Solvability> map;
      output list<ComponentRef> XX = {};
      output list<ComponentRef> II = {};
      output list<ComponentRef> NM = {};
      output list<ComponentRef> NP = {};
      output list<ComponentRef> LV = {};
      output list<ComponentRef> LP = {};
      output list<ComponentRef> LC = {};
      output list<ComponentRef> QQ = {};
    algorithm
      for cref in crefs loop
        _ := match UnorderedMap.getSafe(cref, map, sourceInfo())
          case UNSOLVABLE()                       algorithm XX := cref :: XX; then();
          case IMPLICIT()                         algorithm II := cref :: II; then();
          case EXPLICIT_NONLINEAR(unique = false) algorithm NM := cref :: NM; then();
          case EXPLICIT_NONLINEAR()               algorithm NP := cref :: NP; then();
          case EXPLICIT_LINEAR(vars = SOME(_))    algorithm LV := cref :: LV; then();
          case EXPLICIT_LINEAR(pars = SOME(_))    algorithm LP := cref :: LP; then();
          case EXPLICIT_LINEAR()                  algorithm LC := cref :: LC; then();
          else                                    algorithm QQ := cref :: QQ; then();
        end match;
      end for;
    end categorize;

    function filter
      "filters the cref list for all relevant crefs (checked with the rel map)
      and with solvability ranking between (and including) min and max"
      input list<ComponentRef> all_occ;
      input UnorderedMap<ComponentRef, Solvability> map;
      input UnorderedMap<ComponentRef, Integer> rel       "check for relevance";
      input Integer min;
      input Integer max;
      output list<ComponentRef> occ = {};
    protected
      Integer r;
    algorithm
      for cref in all_occ loop
        if UnorderedMap.contains(cref, rel) then
          r := rank(UnorderedMap.getSafe(cref, map, sourceInfo()));
          if r >= min and r <= max then
            occ := cref :: occ;
          end if;
        end if;
      end for;
    end filter;

    function fromStrictness
      input MatrixStrictness st;
      output Solvability sol;
    algorithm
      sol := match st
        case MatrixStrictness.LINEAR    then EXPLICIT_LINEAR(NONE(), SOME(UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual)));
        case MatrixStrictness.MATCHING  then IMPLICIT();
        case MatrixStrictness.SORTING   then UNSOLVABLE();
        else                                 UNKNOWN();
      end match;
    end fromStrictness;

    function isNonlinearOrImplicit
      input Solvability sol;
      output Boolean b;
    algorithm
      b := match sol
        case EXPLICIT_NONLINEAR() then true;
        case IMPLICIT()           then true;
        else false;
      end match;
    end isNonlinearOrImplicit;
  end Solvability;

  function collectDependenciesEquation
    "collects all relevant component references from an equation
    furthermore it collects additional data about dependency and solvability."
    input Equation eqn;
    input Partition.Kind kind;
    input UnorderedMap<ComponentRef, Integer> map "unordered map to check for relevance";
    input UnorderedMap<ComponentRef, Dependency> dep_map;
    input UnorderedMap<ComponentRef, Solvability> sol_map;
    input UnorderedSet<ComponentRef> rep_set;
    output UnorderedSet<ComponentRef> occurrences;
  protected
    list<ComponentRef> inputs, outputs;
  algorithm
    occurrences := match eqn
      local
        UnorderedSet<ComponentRef> occ1, occ2;
        Equation body;
        Slice.filterCref filter;

      case Equation.SCALAR_EQUATION() algorithm
        occ1 := collectDependencies(eqn.lhs, 0, map, dep_map, sol_map, rep_set);
        occ2 := collectDependencies(eqn.rhs, 0, map, dep_map, sol_map, rep_set);
      then UnorderedSet.union(occ1, occ2);

      case Equation.ARRAY_EQUATION() algorithm
        occ1 := collectDependencies(eqn.lhs, 0, map, dep_map, sol_map, rep_set);
        occ2 := collectDependencies(eqn.rhs, 0, map, dep_map, sol_map, rep_set);
      then UnorderedSet.union(occ1, occ2);

      case Equation.RECORD_EQUATION() algorithm
        occ1 := collectDependencies(eqn.lhs, 0, map, dep_map, sol_map, rep_set);
        occ2 := collectDependencies(eqn.rhs, 0, map, dep_map, sol_map, rep_set);
      then UnorderedSet.union(occ1, occ2);

      case Equation.ALGORITHM() algorithm
        // filter inputs for solvable (not occuring only in conditions)
        inputs := collectDependenciesAlgorithmInputs(eqn.alg.statements, eqn.alg.inputs);
        // collect all crefs expanding potential records
        inputs  := List.flatten(list(collectDependenciesCref(c, 0, map, dep_map, sol_map) for c in inputs));
        outputs := List.flatten(list(collectDependenciesCref(c, 0, map, dep_map, sol_map) for c in eqn.alg.outputs));
        // create dependencies for inputs and outputs
        Dependency.addListFull(inputs, 0, dep_map, rep_set);
        Dependency.addListFull(outputs, 0, dep_map, rep_set);
        // make inputs unsolvable and outputs solvable (maybe check if algorithm can be reversed)
        Solvability.updateList(inputs, Solvability.IMPLICIT(), sol_map);
        Solvability.updateList(outputs, Solvability.EXPLICIT_LINEAR(NONE(), NONE()), sol_map);
      then UnorderedSet.fromList(listAppend(inputs, outputs), ComponentRef.hash, ComponentRef.isEqual);

      case Equation.FOR_EQUATION(body = {body}) algorithm
        // gather solvables from body
        occ1 := collectDependenciesEquation(body, kind, map, dep_map, sol_map, rep_set);
        // gather unsolvables from iterator
        occ2 := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
        filter := function Slice.getDependentCref(map = map, pseudo = true);
        _ := Iterator.map(eqn.iter, function Slice.filterExp(filter = filter, acc = occ2),
          SOME(function filter(acc = occ2)), Expression.mapShallow);
        // update unsolvables
        Solvability.updateList(UnorderedSet.toList(occ2), Solvability.UNSOLVABLE(), sol_map);
      then UnorderedSet.union(occ1, occ2);

      case Equation.IF_EQUATION()
      then collectDependenciesIf(eqn.body, kind, map, dep_map, sol_map, rep_set);

      case Equation.WHEN_EQUATION()
      then collectDependenciesWhen(eqn.body, kind, map, dep_map, sol_map, rep_set);

      else UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    end match;
  end collectDependenciesEquation;

  function collectDependencies
    "collects all relevant component references from an expression
    furthermore it collects additional data about dependency and solvability."
    input Expression exp;
    input Integer depth;
    input UnorderedMap<ComponentRef, Integer> map "unknowns map to check for relevance";
    input UnorderedMap<ComponentRef, Dependency> dep_map;
    input UnorderedMap<ComponentRef, Solvability> sol_map;
    input UnorderedSet<ComponentRef> rep_set;
    output UnorderedSet<ComponentRef> set;
  algorithm
    set := match exp
      local
        Dependency dep;
        UnorderedSet<ComponentRef> set1, set2, diff;
        list<UnorderedSet<ComponentRef>> sets = {};
        Expression call_exp;
        Call call;
        Boolean repeatLeft, repeatRight, reduce;
        Integer ind, new_depth;
        Boolean isTuple;

      // add a cref dependency
      case Expression.CREF() algorithm
        set := UnorderedSet.fromList(collectDependenciesCref(exp.cref, depth, map, dep_map, sol_map), ComponentRef.hash, ComponentRef.isEqual);
        // variables in subscripts (e.g. idx in y = val[idx]) have to be known before, but cannot be solved for
        for sub in ComponentRef.subscriptsAllFlat(exp.cref) loop
          if (Subscript.isIndex(sub) or (Subscript.isSliced(sub) and not Subscript.isWhole(sub))) and not Subscript.isLiteral(sub) then
            set2 := collectDependencies(Subscript.toExp(sub), depth, map, dep_map, sol_map, rep_set);
            Solvability.updateList(UnorderedSet.toList(set2), Solvability.UNSOLVABLE(), sol_map);
            set := UnorderedSet.union(set, set2);
          end if;
        end for;
      then set;

      // add skips for arrays
      case Expression.ARRAY(literal = false) algorithm
        for i in 1:arrayLength(exp.elements) loop
          set1 := collectDependencies(exp.elements[i], depth + 1, map, dep_map, sol_map, rep_set);
          Dependency.skipList(UnorderedSet.toList(set1), depth + 1, i, dep_map);
          sets := set1 :: sets;
        end for;
      then UnorderedSet.union_list(sets, ComponentRef.hash, ComponentRef.isEqual);

      // add skips for tuples
      case Expression.TUPLE() algorithm
        ind := 1;
        for elem in exp.elements loop
          set1 := collectDependencies(elem, depth + 1, map, dep_map, sol_map, rep_set);
          Dependency.skipList(UnorderedSet.toList(set1), depth + 1, ind, dep_map);
          sets := set1 :: sets;
          ind := ind + 1;
        end for;
        set := UnorderedSet.union_list(sets, ComponentRef.hash, ComponentRef.isEqual);
      then set;

      // reduce the dependency and remove skips for these
      case Expression.SUBSCRIPTED_EXP() algorithm
        set := collectDependencies(exp.exp, depth, map, dep_map, sol_map, rep_set);
        Dependency.updateList(UnorderedSet.toList(set), listLength(exp.subscripts), true, dep_map);
        Dependency.removeSkipsList(UnorderedSet.toList(set), dep_map);
        // collect dependencies from subscript expressions (e.g. arr[i] depends on i)
        // subscript variables are unsolvable (cannot determine i from arr[i] = c)
        for sub in exp.subscripts loop
          set2 := match sub
            case Subscript.INDEX() then collectDependencies(sub.index, 0, map, dep_map, sol_map, rep_set);
            case Subscript.SLICE() then collectDependencies(sub.slice, 0, map, dep_map, sol_map, rep_set);
            else UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
          end match;
          Solvability.updateList(UnorderedSet.toList(set2), Solvability.UNSOLVABLE(), sol_map);
          set := UnorderedSet.union(set, set2);
        end for;
      then set;

      // should not change anything
      case Expression.TUPLE_ELEMENT()   then collectDependencies(exp.tupleExp, depth, map, dep_map, sol_map, rep_set);
      case Expression.RECORD_ELEMENT()  then collectDependencies(exp.recordExp, depth, map, dep_map, sol_map, rep_set);

      case Expression.BINARY() algorithm
        set1  := collectDependencies(exp.exp1, depth, map, dep_map, sol_map, rep_set);
        set2  := collectDependencies(exp.exp2, depth, map, dep_map, sol_map, rep_set);
        // add repetitions if needed (.+, .*)
        (repeatLeft, repeatRight) := Operator.repetition(exp.operator);
        if repeatLeft then addRepetitions(set1, rep_set); end if;
        if repeatRight then addRepetitions(set2, rep_set); end if;
        // add reductions if needed
        reduce := Operator.reduction(exp.operator);
        if reduce then
          Dependency.updateList(UnorderedSet.toList(set1), 1, true, dep_map);
          Dependency.updateList(UnorderedSet.toList(set2), 1, false, dep_map);
          // a scalar result has no elements to skip to, e.g. {1, 2} * {x, y}
          if not Type.isArray(Expression.typeOf(exp)) then
            Dependency.removeSkipsList(UnorderedSet.toList(set1), dep_map);
            Dependency.removeSkipsList(UnorderedSet.toList(set2), dep_map);
          end if;
        end if;
      then UnorderedSet.union(set1, set2);

      // mostly equal to binary
      case Expression.MULTARY() algorithm
        // add repetitions if needed (.+, .*)
        (repeatLeft, repeatRight) := Operator.repetition(exp.operator);
        repeatLeft := repeatLeft or repeatRight;
        // traverse arguments
        for arg in exp.arguments loop
          set1 := collectDependencies(arg, depth, map, dep_map, sol_map, rep_set);
          // add repetitions if needed
          addRepetitionsCond(set1, arg, repeatLeft, rep_set);
          sets := set1 :: sets;
        end for;
        // traverse inverse arguments
        for arg in exp.inv_arguments loop
          set2 := collectDependencies(arg, depth, map, dep_map, sol_map, rep_set);
          // add repetitions if needed
          addRepetitionsCond(set2, arg, repeatLeft, rep_set);
          sets := set2 :: sets;
        end for;
        set := UnorderedSet.union_list(sets, ComponentRef.hash, ComponentRef.isEqual);
      then set;

      // cannot solve from lbinary
      case Expression.LBINARY() algorithm
        set1  := collectDependencies(exp.exp1, depth, map, dep_map, sol_map, rep_set);
        set2  := collectDependencies(exp.exp2, depth, map, dep_map, sol_map, rep_set);
        set   := UnorderedSet.union(set1, set2);
        Solvability.updateList(UnorderedSet.toList(set), Solvability.UNSOLVABLE(), sol_map);
      then set;

      // cannot solve from relation
      case Expression.RELATION() algorithm
        set1  := collectDependencies(exp.exp1, depth, map, dep_map, sol_map, rep_set);
        set2  := collectDependencies(exp.exp2, depth, map, dep_map, sol_map, rep_set);
        set   := UnorderedSet.union(set1, set2);
        Solvability.updateList(UnorderedSet.toList(set), Solvability.UNSOLVABLE(), sol_map);
      then set;

      // these don't really change anything, just pass on the argument
      case Expression.CAST()    then collectDependencies(exp.exp, depth, map, dep_map, sol_map, rep_set);
      case Expression.BOX()     then collectDependencies(exp.exp, depth, map, dep_map, sol_map, rep_set);
      case Expression.UNBOX()   then collectDependencies(exp.exp, depth, map, dep_map, sol_map, rep_set);
      case Expression.UNARY()   then collectDependencies(exp.exp, depth, map, dep_map, sol_map, rep_set);
      case Expression.LUNARY()  then collectDependencies(exp.exp, depth, map, dep_map, sol_map, rep_set);
      case Expression.MUTABLE() then collectDependencies(Mutable.access(exp.exp), depth, map, dep_map, sol_map, rep_set);

      // in the size() operator nothing is solvable
      case Expression.SIZE() algorithm
        set  := collectDependencies(exp.exp, depth, map, dep_map, sol_map, rep_set);
        if isSome(exp.dimIndex) then
          set2  := collectDependencies(Util.getOption(exp.dimIndex), depth, map, dep_map, sol_map, rep_set);
          set := UnorderedSet.union(set, set2);
        end if;
        Solvability.updateList(UnorderedSet.toList(set), Solvability.UNSOLVABLE(), sol_map);
      then set;

      // variables in conditions are unsolvable and variables not occuring in both branches are implicit
      case Expression.IF() algorithm
        set1  := collectDependencies(exp.trueBranch, depth, map, dep_map, sol_map, rep_set);
        set2  := collectDependencies(exp.falseBranch, depth, map, dep_map, sol_map, rep_set);
        // variables not occuring in both branches will be tagged implicit
        diff  := UnorderedSet.sym_difference(set1, set2);
        Solvability.updateList(UnorderedSet.toList(diff), Solvability.IMPLICIT(), sol_map);
        // variables in conditions are unsolvable, their skips have to be removed and they can be repeated
        set   := collectDependencies(exp.condition, depth, map, dep_map, sol_map, rep_set);
        addRepetitions(set, rep_set);
        updateConditionCrefs(UnorderedSet.toList(set), dep_map, sol_map);
      then UnorderedSet.union_list({set, set1, set2}, ComponentRef.hash, ComponentRef.isEqual);

      // for array constructors replace all iterators (temporarily)
      case Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR(exp = call_exp)) algorithm
        for iter in call.iters loop
          call_exp := Expression.replaceIterator(call_exp, Util.tuple21(iter), Util.tuple22(iter));
        end for;
        // if these are not simplified before this step, they can only be solved implicitely
        set := collectDependencies(call_exp, depth, map, dep_map, sol_map, rep_set);
        Solvability.updateList(UnorderedSet.toList(set), Solvability.IMPLICIT(), sol_map);
      then set;

      // for reductions set the dependency to full reduction
      case Expression.CALL(call = call as Call.TYPED_REDUCTION(exp = call_exp)) algorithm
        for iter in call.iters loop
          call_exp := Expression.replaceIterator(call_exp, Util.tuple21(iter), Util.tuple22(iter));
        end for;
        set := collectDependencies(call_exp, depth, map, dep_map, sol_map, rep_set);
        Dependency.updateList(UnorderedSet.toList(set), -1, false, dep_map);
      then set;

      // for functions set the dependency to full reduction (+ repetition) and solvability to implicit
      case Expression.CALL(call = call as Call.TYPED_CALL()) algorithm
        // add depth if return type is tuple
        isTuple := Type.isTuple(call.ty);
        new_depth := if isTuple then depth + 1 else depth;
        for arg in call.arguments loop
          sets := collectDependencies(arg, new_depth, map, dep_map, sol_map, rep_set) :: sets;
        end for;
        set := UnorderedSet.union_list(sets, ComponentRef.hash, ComponentRef.isEqual);
        Dependency.updateList(UnorderedSet.toList(set), -1, false, dep_map);
        // discrete arguments cannot be iterated on and no argument can be solved from a
        // discrete result (e.g. integer(x)), so they are unsolvable
        for cref in UnorderedSet.toList(set) loop
          Solvability.update(cref, if not Type.isDiscrete(call.ty) and BVariable.checkCref(cref, function BVariable.isContinuous(staticAsContinuous = true), sourceInfo())
            then Solvability.IMPLICIT() else Solvability.UNSOLVABLE(), sol_map);
        end for;
        addRepetitions(set, rep_set);
        // if the return type has to be skipped - add empty skip
        if isTuple then
          Dependency.skipList(UnorderedSet.toList(set), depth + 1, 0, dep_map);
        end if;
      then set;

      // for not inlined record constructors set the dependency to full reduction (+ repetition) and solvability to implicit
      case Expression.RECORD() algorithm
        for arg in exp.elements loop
          sets := collectDependencies(arg, depth, map, dep_map, sol_map, rep_set) :: sets;
        end for;
        set := UnorderedSet.union_list(sets, ComponentRef.hash, ComponentRef.isEqual);
        Dependency.updateList(UnorderedSet.toList(set), -1, false, dep_map);
        Solvability.updateList(UnorderedSet.toList(set), Solvability.IMPLICIT(), sol_map);
        addRepetitions(set, rep_set);
      then set;

      // nothing is solvable from ranges
      case Expression.RANGE() algorithm
        sets := collectDependencies(exp.start, depth, map, dep_map, sol_map, rep_set) :: sets;
        if isSome(exp.step) then
          sets := collectDependencies(Util.getOption(exp.step), depth, map, dep_map, sol_map, rep_set) :: sets;
        end if;
        sets := collectDependencies(exp.stop, depth, map, dep_map, sol_map, rep_set) :: sets;
        set := UnorderedSet.union_list(sets, ComponentRef.hash, ComponentRef.isEqual);
        Solvability.updateList(UnorderedSet.toList(set), Solvability.UNSOLVABLE(), sol_map);
      then set;

      else UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    end match;
  end collectDependencies;

  function collectDependenciesCref
    input ComponentRef cref;
    input Integer depth;
    input UnorderedMap<ComponentRef, Integer> map "unknowns map to check for relevance";
    input UnorderedMap<ComponentRef, Dependency> dep_map;
    input UnorderedMap<ComponentRef, Solvability> sol_map;
    output list<ComponentRef> crefs;
  protected
    Pointer<Variable> var;
    Integer sk = 1;
    list<Subscript> subs;
    list<ComponentRef> scalar_matches;
    Boolean hasSetSub = false;
    Option<Pointer<Variable>> parent_opt;
    Pointer<Variable> parent;
    ComponentRef parent_name;
  algorithm
    for s in ComponentRef.subscriptsAllFlat(cref) loop
      // WHOLE (":") and SLICE (e.g. "1:3") are ordinary, common range subscripts
      // that the exact-match check below already handles correctly -- only a
      // literal/array-valued INDEX subscript (e.g. the "{1, 2}" in i_s[{1, 2}])
      // is the set-subscript case this function needs to special-case.
      if not Subscript.isScalar(s) and not Subscript.isSliced(s) then
        hasSetSub := true;
      end if;
    end for;

    // a cref with a set/array-valued subscript (e.g. i_s[{1, 2}], produced when a torn
    // slice's residual equation keeps its original vector-valued RHS subexpression --
    // see NBTearing.scalarSlices) must not go through the ordinary exact-match check
    // below: "map" here can use stripped (subscript-ignoring) cref equality
    // (VariablePointers' non-scalarized mode), under which i_s[{1, 2}] can spuriously
    // "contain"-match some unrelated whole-array entry for the same base variable,
    // recording that wrong, un-scalarized cref as the dependency and silently breaking
    // the seed/column mapping in fullToSparsity downstream (whose seed set is matched by
    // strict, non-stripped equality). Resolve those via their individual scalar elements
    // instead, matched strictly against map.
    if not hasSetSub and UnorderedMap.contains(cref, map) then
      if not UnorderedMap.contains(cref, dep_map) then
        UnorderedMap.add(cref, Dependency.create(ComponentRef.getSubscriptedType(cref), depth), dep_map);
      end if;
      Solvability.update(cref, Solvability.EXPLICIT_LINEAR(NONE(), NONE()), sol_map);
      crefs := {cref};
      return;
    end if;

    // a slice (e.g. i[1:2]) of variables whose elements are the unknowns is resolved via its elements as well
    if not hasSetSub and Type.isArray(ComponentRef.getSubscriptedType(cref)) and Type.hasKnownSize(ComponentRef.getSubscriptedType(cref)) and Type.sizeOf(ComponentRef.getSubscriptedType(cref)) <= 256 then
      hasSetSub := true;
    end if;

    if hasSetSub then
      scalar_matches := list(c for c guard(UnorderedMap.contains(c, map)) in ComponentRef.scalarize(cref, false));
      if not listEmpty(scalar_matches) then
        for c in scalar_matches loop
          if not UnorderedMap.contains(c, dep_map) then
            UnorderedMap.add(c, Dependency.create(ComponentRef.getSubscriptedType(c), depth), dep_map);
          end if;
          Solvability.update(c, Solvability.EXPLICIT_LINEAR(NONE(), NONE()), sol_map);
        end for;
        crefs := scalar_matches;
        return;
      end if;
    end if;

    var := BVariable.getVarPointer(cref, sourceInfo());
    if BVariable.isRecord(var) then
      subs := ComponentRef.subscriptsAllFlat(cref);
      // get all Record children that are relevant for current context
      crefs := list(BVariable.getVarName(child) for child in BVariable.getRecordChildren(var));
      crefs := list(child for child guard(UnorderedMap.contains(child, map)) in crefs);
      // add original subscripts
      crefs := list(ComponentRef.mergeSubscripts(subs, child) for child in crefs);
      // collect dependencies
      crefs := List.flatten(list(collectDependenciesCref(child, depth + 1, map, dep_map, sol_map) for child in crefs));
      for cref in crefs loop
        Dependency.skip(cref, depth + 1, sk, dep_map);
        sk := sk + 1;
      end for;
    else
      crefs := {};
      // an element of a record that is an unknown as a whole (e.g. a record parameter
      // solved by its binding) depends on the record, but cannot be solved for
      parent_opt := BVariable.getParent(var);
      while isSome(parent_opt) loop
        parent := Util.getOption(parent_opt);
        if BVariable.isArray(parent) then
          break;
        end if;
        parent_name := BVariable.getVarName(parent);
        if UnorderedMap.contains(parent_name, map) then
          if not UnorderedMap.contains(parent_name, dep_map) then
            UnorderedMap.add(parent_name, Dependency.create(ComponentRef.getSubscriptedType(parent_name), depth), dep_map);
          end if;
          Solvability.update(parent_name, Solvability.UNSOLVABLE(), sol_map);
          crefs := {parent_name};
          break;
        end if;
        parent_opt := BVariable.getParent(parent);
      end while;
    end if;
  end collectDependenciesCref;

  function addRepetitionsCond
    "adds component references from a set to the repetition set,
    only if the expression they appear in is of size 1"
    input UnorderedSet<ComponentRef> occ;
    input Expression exp;
    input Boolean isRep;
    input UnorderedSet<ComponentRef> rep_set;
  algorithm
    if isRep and Type.sizeOf(Expression.typeOf(exp)) == 1 then
      addRepetitions(occ, rep_set);
    end if;
  end addRepetitionsCond;

  function addRepetitions
    "adds component references to the repetition set"
    input UnorderedSet<ComponentRef> occ;
    input UnorderedSet<ComponentRef> rep_set;
  algorithm
    for cref in UnorderedSet.toList(occ) loop
      UnorderedSet.add(cref, rep_set);
    end for;
  end addRepetitions;

  function collectDependenciesIf
    "collects all relevant component references from an if equation body
    furthermore it collects additional data about dependency and solvability.
    variables in conditions and variables not contained in all branches are unsolvable"
    input IfEquationBody body;
    input Partition.Kind kind;
    input UnorderedMap<ComponentRef, Integer> map "unordered map to check for relevance";
    input UnorderedMap<ComponentRef, Dependency> dep_map;
    input UnorderedMap<ComponentRef, Solvability> sol_map;
    input UnorderedSet<ComponentRef> rep_set;
    output UnorderedSet<ComponentRef> set;
  protected
    list<UnorderedSet<ComponentRef>> sets1 = {};
    UnorderedSet<ComponentRef> set1, set2, diff;
  algorithm
    // variables in conditions are unsolvable, repeated and get their skips removed
    set := collectDependencies(body.condition, 0, map, dep_map, sol_map, rep_set);
    addRepetitions(set, rep_set);
    updateConditionCrefs(UnorderedSet.toList(set), dep_map, sol_map);

    // get variables from 'then' branch
    for eqn in body.then_eqns loop
      sets1  := collectDependenciesEquation(Pointer.access(eqn), kind, map, dep_map, sol_map, rep_set) :: sets1;
    end for;

    // if there is an 'else' branch, mark those not occuring in both as implicit (maybe it should be unsolvable?)
    if isSome(body.else_if) then
      set1 := UnorderedSet.union_list(sets1, ComponentRef.hash, ComponentRef.isEqual);
      set2 := collectDependenciesIf(Util.getOption(body.else_if), kind, map, dep_map, sol_map, rep_set);
      diff  := UnorderedSet.sym_difference(set1, set2);
      Solvability.updateList(UnorderedSet.toList(diff), Solvability.IMPLICIT(), sol_map);
      set := UnorderedSet.union_list({set, set1, set2}, ComponentRef.hash, ComponentRef.isEqual);
    else
      set := UnorderedSet.union_list(set :: sets1, ComponentRef.hash, ComponentRef.isEqual);
    end if;
  end collectDependenciesIf;

  function collectDependenciesWhen
    "collects all relevant component references from a when equation body
    furthermore it collects additional data about dependency and solvability.
    variables assigned on the left hand side are solvable,
    variables from the right hand side (-lhs variables) are unsolvable"
    input WhenEquationBody body;
    input Partition.Kind kind;
    input UnorderedMap<ComponentRef, Integer> map "unordered map to check for relevance";
    input UnorderedMap<ComponentRef, Dependency> dep_map;
    input UnorderedMap<ComponentRef, Solvability> sol_map;
    input UnorderedSet<ComponentRef> rep_set;
    output UnorderedSet<ComponentRef> set;
  protected
    UnorderedSet<ComponentRef> set1 "solvables";
    UnorderedSet<ComponentRef> set2 "potentially unsolvables";
    UnorderedSet<ComponentRef> diff "set2 / set1 unsolvables";
    list<UnorderedSet<ComponentRef>> lst = {}, lst1, lst2;
    list<tuple<UnorderedSet<ComponentRef>, UnorderedSet<ComponentRef>>> tpl_lst = {};
  algorithm
    // variables in conditions are unsolvable, reduced and get their skips removed
    set := collectDependencies(body.condition, 0, map, dep_map, sol_map, rep_set);
    updateConditionCrefs(UnorderedSet.toList(set), dep_map, sol_map);

    // make condition repeat if the body is larger than 1
    if sum(WhenStatement.size(stmt, true) for stmt in body.when_stmts) > 1 then
      addRepetitions(set, rep_set);
    end if;

    // collect all dependencies from the statments
    for stmt in body.when_stmts loop
      tpl_lst := collectDependenciesStmt(stmt, map, dep_map, sol_map, rep_set) :: tpl_lst;
    end for;

    // create the two sets for solvables and potentially unsovables
    (lst1, lst2) := List.unzip(tpl_lst);
    set1 := UnorderedSet.union_list(lst1, ComponentRef.hash, ComponentRef.isEqual);
    set2 := UnorderedSet.union_list(lst2, ComponentRef.hash, ComponentRef.isEqual);

    // get the set difference to determine the unsolvables and tag them as such
    diff := UnorderedSet.difference(set2, set1);
    Solvability.updateList(UnorderedSet.toList(diff), Solvability.UNSOLVABLE(), sol_map);

    // traverse else when if it exists
    if isSome(body.else_when) then
      lst := collectDependenciesWhen(Util.getOption(body.else_when), kind, map, dep_map, sol_map, rep_set) :: lst;
    end if;
    set := UnorderedSet.union_list(set :: set1 :: set2 :: lst, ComponentRef.hash, ComponentRef.isEqual);
  end collectDependenciesWhen;

  function collectDependenciesStmt
    "collects all relevant component references from a when statement
    furthermore it collects additional data about dependency and solvability.
    Returns a tuple of two sets, one containing the solvables and the other
    containing potentially unsolvables"
    input WhenStatement stmt;
    input UnorderedMap<ComponentRef, Integer> map "unordered map to check for relevance";
    input UnorderedMap<ComponentRef, Dependency> dep_map;
    input UnorderedMap<ComponentRef, Solvability> sol_map;
    input UnorderedSet<ComponentRef> rep_set;
    output tuple<UnorderedSet<ComponentRef>, UnorderedSet<ComponentRef>> set_tpl;
  protected
    UnorderedSet<ComponentRef> set1 "solvable";
    UnorderedSet<ComponentRef> set2 "potentially unsolvable";
  algorithm
    set_tpl := match stmt
      case WhenStatement.ASSIGN() algorithm
        set1 := collectDependencies(stmt.lhs, 0, map, dep_map, sol_map, rep_set);
        set2 := collectDependencies(stmt.rhs, 0, map, dep_map, sol_map, rep_set);
      then (set1, set2);

      case WhenStatement.REINIT() algorithm
        set1 := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
        set2 := collectDependencies(stmt.value, 0, map, dep_map, sol_map, rep_set);
      then (set1, set2);

      case WhenStatement.ASSERT() algorithm
        set1 := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
        set2 := collectDependencies(stmt.condition, 0, map, dep_map, sol_map, rep_set);
        updateConditionCrefs(UnorderedSet.toList(set2), dep_map, sol_map);
      then (set1, set2);

      else algorithm
        set1 := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
        set2 := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
      then (set1, set2);
    end match;
  end collectDependenciesStmt;

  function collectDependenciesAlgorithmInputs
    "collects dependencies from algorithm inputs.
    Only consider inputs that appear outside of when/if conditions"
    input list<Statement> stmts;
    input output list<ComponentRef> inputs;
  protected
    UnorderedSet<ComponentRef> candidates = UnorderedSet.fromList(inputs, ComponentRef.hash, ComponentRef.isEqual);
    UnorderedSet<ComponentRef> result = UnorderedSet.fromList(inputs, ComponentRef.hash, ComponentRef.isEqual);
  algorithm
    for stmt in stmts loop
      collectDependenciesAlgorithmStatement(stmt, candidates, result);
    end for;
    inputs := UnorderedSet.toList(result);
  end collectDependenciesAlgorithmInputs;

  function collectDependenciesAlgorithmStatement
    input Statement stmt;
    input UnorderedSet<ComponentRef> candidates;
    input UnorderedSet<ComponentRef> result;
  algorithm
    _ := match stmt

      // actual occurence can only happen here
      case Statement.ASSIGNMENT() algorithm
        Slice.filterExp(stmt.lhs, function Equation.collectFromSet(check_set = candidates), result);
        Slice.filterExp(stmt.rhs, function Equation.collectFromSet(check_set = candidates), result);
      then ();

      // map body
      case Statement.FOR() algorithm
        for s in stmt.body loop
          collectDependenciesAlgorithmStatement(s, candidates, result);
        end for;
      then ();

      // map body
      case Statement.WHILE() algorithm
        for s in stmt.body loop
          collectDependenciesAlgorithmStatement(s, candidates, result);
        end for;
      then ();

      // skip conditions but map body
      case Statement.IF() algorithm
        for branch in stmt.branches loop
          for s in Util.tuple22(branch) loop
            collectDependenciesAlgorithmStatement(s, candidates, result);
          end for;
        end for;
      then ();

      // skip conditions but map body
      case Statement.WHEN() algorithm
        for branch in stmt.branches loop
          for s in Util.tuple22(branch) loop
            collectDependenciesAlgorithmStatement(s, candidates, result);
          end for;
        end for;
      then ();

      // all other cases do not produce an occurence
      else ();
    end match;
  end collectDependenciesAlgorithmStatement;

  function updateConditionCrefs
    "variables in conditions are unsolvable, reduced and get their skips removed"
    input list<ComponentRef> crefs;
    input UnorderedMap<ComponentRef, Dependency> dep_map;
    input UnorderedMap<ComponentRef, Solvability> sol_map;
  algorithm
    Dependency.removeSkipsList(crefs, dep_map);
    Dependency.updateList(crefs, -1, false, dep_map);
    Solvability.updateList(crefs, Solvability.UNSOLVABLE(), sol_map);
  end updateConditionCrefs;

  function addInitialStartOccurrences
    "in the initial system start value dependencies must be included.
      - x has a start value x.start which is unfixed
      - x is iteration variable in an algebraic loop
      - the equation for x.start has to be solved before x is used"
    input UnorderedSet<ComponentRef> occs;
    input UnorderedMap<ComponentRef, Dependency> dep_map;
    input UnorderedMap<ComponentRef, Solvability> sol_map;
    input UnorderedSet<ComponentRef> rep_set;
    input Partition.Kind kind;
  algorithm
    // only do something if its an initial partition
    if Partition.kindIsInitial(kind) then
      for cref in UnorderedSet.toList(occs) loop
        () := match BVariable.getVarStart(BVariable.getVarPointer(cref, sourceInfo()))
          local
            Pointer<Variable> start;
            ComponentRef start_cref;

          // only save the x -> x.start dependency not the other way around
          case SOME(start) guard(BVariable.isStart(start)) algorithm
            start_cref := ComponentRef.copySubscripts(cref, BVariable.getVarName(start));
            // add the start cref dependency in the same way the original variable occured
            // but with UNSOLVABLE as it is only relevant for sorting and cannot be solved
            UnorderedSet.add(start_cref, occs);
            UnorderedMap.add(start_cref, UnorderedMap.getSafe(cref, dep_map, sourceInfo()), dep_map);
            UnorderedMap.add(start_cref, Solvability.UNSOLVABLE(), sol_map);
            if UnorderedSet.contains(cref, rep_set) then
              UnorderedSet.add(start_cref, rep_set);
            end if;
          then ();
          else ();
        end match;
      end for;
    end if;
  end addInitialStartOccurrences;

  annotation(__OpenModelica_Interface="nbackend");
end NBAdjacency;
