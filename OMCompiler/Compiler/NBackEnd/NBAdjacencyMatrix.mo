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
encapsulated package NBAdjacencyMatrix
" file:         NAdjacencyMatrix.mo
  description:  This file contains the data-types used for the adjacency matrix
                and matching and the corresponding functions.
"

public uniontype AdjacencyMatrix
  record ARRAY_ADJACENCY_MATRIX
    AdjacencyMatrixQuarter adjacencyMatrix;
    AdjacencyMatrixQuarterT adjacencyMatrixT;
    /* Maybe add optional markings here */
  end ARRAY_ADJACENCY_MATRIX;

  record SCALAR_ADJACENCY_MATRIX
    /* support old structure? */
  end SCALAR_ADJACENCY_MATRIX;
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

type Matching = array<list<SliceAssignment>>;


annotation(__OpenModelica_Interface="backend");
end NBAdjacencyMatrix;
