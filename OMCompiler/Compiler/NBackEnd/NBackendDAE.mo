/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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
encapsulated package NBackendDAE
" file:        NBackendDAE.mo
 package:     NBackendDAE
 description: This file contains the data-types used by the back end.
"
 uniontype BackendStructure
 record BDAE
   /* Stuff here! */
 end BDAE;
end BackendStructure;

/* ========================================================
               ADJACENCY MATRIX AND MATCHING
   ======================================================== */

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
    array<Integer> dimSizes         "Sizes for each dimension.";
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
    array<Integer> dimSizes         "Sizes for each dimension.";
    list<IndexSlice> indSlice       "Indexed slice for each appearing variable or equation.";
  end ADJACENCY_ROW;
end AdjacencyRow;

type AdjacencyMatrix = array<AdjacencyRow>;


/* New matching structure for slice matching */
uniontype SliceAssignment
  record SLICE_ASSIGNMENT
    TensorSlice tenSlice         "Assigned tensor slice of current row";
    IndexSlice indSlice          "Assigned tensor slice of indexed column";
  end SLICE_ASSIGNMENT;
end SliceAssignment;

type Matching = array<list<SliceAssignment>>;

/* OLD BAD IDEA I DONT WANT TO SCRAP RN */
 /* --- Slices of one dimension ---
uniontype RegularSlice
  record REG_SLICE
    Integer Start;
    Integer Stop;
    Integer Step;
  end REG_SLICE;
  /* maybe we need more here
end RegularSlice;

uniontype Slice
  record SLICE
    "Full dimension slice."
    list<Integer> singletons       "List of single unordered indices.";
    list<RegularSlice> regSlices   "List of regular slicings.";
  end SLICE;
end Slice;

/* --- Slices of multiple dimensions ---
uniontype TensorSlice
  record TENSOR_SLICE
    "Slice through all dimensions."
    array<Integer> dimSizes         "Size of each dimension.";
    array<Slice> slices             "Single dimension slicings.";
  end TENSOR_SLICE;
end TensorSlice;

/* General indexed slice. The index refers to the
   variable or equation the slice belongs to.
uniontype IndexSlice
  record SCALAR_INDEX_SLICE
  end SCALAR_INDEX_SLICE;

  record VECTOR_INDEX_SLICE
  end VECTOR_INDEX_SLICE;

  record TENSOR_INDEX_SLICE
  end TENSOR_INDEX_SLICE;
end IndexSlice;
*/

annotation(__OpenModelica_Interface="backend");
end NBackendDAE;
