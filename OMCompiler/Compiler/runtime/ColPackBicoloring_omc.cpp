/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
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
 */

/*
 * ColPack star bicoloring wrapper for OpenModelica.
 *
 * Provides a C-callable interface to ColPack's BipartiteGraphBicoloring
 * that can be invoked from MetaModelica via external "C" declarations.
 *
 * Input:  Bipartite graph sparsity in CSR format (row pointers + column indices),
 *         using 0-based indexing.
 * Output: Column colors and row colors (1-based; 0 = uncolored by that direction).
 *
 * Reference:
 *   "What Color Is Your Jacobian? Graph Coloring for Computing Derivatives"
 *   Gebremedhin, Manne, Pothen.
 *   https://doi.org/10.1137/S0036144504444711
 */

#ifdef __cplusplus
extern "C" {
#endif

#include "meta/meta_modelica.h"

#ifdef __cplusplus
}
#endif

#ifdef TRUE
#undef TRUE
#endif

#ifdef FALSE
#undef FALSE
#endif

#include <ColPackHeaders.h>

#include <vector>
#include <cstring>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Star bicoloring of a bipartite graph via ColPack.
 *
 * The Jacobian J is m x n (m rows, n columns). The bipartite graph has
 * row-vertices on the left (rows/equations) and column-vertices on the right
 * (columns/variables). An edge (i, j) exists iff J[i][j] != 0.
 *
 * @param nRows       Number of rows (m).
 * @param nCols       Number of columns (n).
 * @param rowPtr      CSR row pointers, size nRows+1, 0-based.
 * @param colIdx      CSR column indices, size nnz, 0-based.
 * @param outColColors  Output: MetaModelica array<Integer> of size nCols (1-based colors; 0 = not column-colored).
 * @param outNColColors Output: Number of column colors used.
 * @param outRowColors  Output: MetaModelica array<Integer> of size nRows (1-based colors; 0 = not row-colored).
 * @param outNRowColors Output: Number of row colors used.
 */
void ColPackBicoloring_starBicolor(
    int nRows,
    int nCols,
    void* mmcRowPtr,    /* MetaModelica array<Integer>, size nRows+1 */
    void* mmcColIdx,    /* MetaModelica array<Integer>, size nnz */
    void** outColColors,
    int* outNColColors,
    void** outRowColors,
    int* outNRowColors)
{
  /* ---- Unpack MetaModelica integer arrays ---- */
  int nnz = MMC_HDRSLOTS(MMC_GETHDR(mmcColIdx));
  int rowPtrLen = nRows + 1;

  /* Build ADOL-C compressed-row format: unsigned int** ppSparsityPattern
   * ppSparsityPattern[i][0] = number of nonzeros in row i
   * ppSparsityPattern[i][1..nnzRow] = column indices (0-based)
   */
  unsigned int** ppSparsityPattern = new unsigned int*[nRows];
  for (int i = 0; i < nRows; i++) {
    int start = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(mmcRowPtr)[i]);
    int end   = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(mmcRowPtr)[i + 1]);
    int nnzRow = end - start;
    ppSparsityPattern[i] = new unsigned int[nnzRow + 1];
    ppSparsityPattern[i][0] = (unsigned int)nnzRow;
    for (int k = 0; k < nnzRow; k++) {
      ppSparsityPattern[i][k + 1] = (unsigned int)MMC_UNTAGFIXNUM(MMC_STRUCTDATA(mmcColIdx)[start + k]);
    }
  }

  /* ---- Call ColPack ---- */
  ColPack::BipartiteGraphBicoloringInterface bgbc(SRC_MEM_ADOLC, ppSparsityPattern, nRows, nCols);
  bgbc.Bicoloring("DYNAMIC_LARGEST_FIRST", "IMPLICIT_COVERING__STAR_BICOLORING");

  /* Extract results.
   * ColPack returns:
   *   left colors  = row colors, size nRows  (0-based; -1 = uncolored by rows)
   *   right colors = column colors, size nCols (0-based; -1 = uncolored by cols)
   * We convert to 1-based (0 = uncolored).
   */
  std::vector<int> leftColors;
  std::vector<int> rightColors;
  bgbc.GetLeftVertexColors(leftColors);
  bgbc.GetRightVertexColors_Transformed(rightColors);

  /* ---- Build MetaModelica output: column colors ---- */
  void* colColorsArr = (void*)mmc_mk_box_no_assign(nCols, MMC_ARRAY_TAG, 0);
  int maxColColor = 0;
  for (int j = 0; j < nCols; j++) {
    int c = (j < (int)rightColors.size()) ? rightColors[j] : 0;
    if (c > 0) {
      if (c > maxColColor) maxColColor = c;
    } else {
      c = 0;  /* uncolored by column direction */
    }
    MMC_STRUCTDATA(colColorsArr)[j] = mmc_mk_icon(c);
  }
  *outColColors = colColorsArr;
  *outNColColors = maxColColor;

  /* ---- Build MetaModelica output: row colors ---- */
  void* rowColorsArr = (void*)mmc_mk_box_no_assign(nRows, MMC_ARRAY_TAG, 0);
  int maxRowColor = 0;
  for (int i = 0; i < nRows; i++) {
    int c = (i < (int)leftColors.size()) ? leftColors[i] : 0;
    if (c > 0) {
      if (c > maxRowColor) maxRowColor = c;
    } else {
      c = 0;
    }
    MMC_STRUCTDATA(rowColorsArr)[i] = mmc_mk_icon(c);
  }
  *outRowColors = rowColorsArr;
  *outNRowColors = maxRowColor;

  /* ---- Cleanup ---- */
  for (int i = 0; i < nRows; i++) {
    delete[] ppSparsityPattern[i];
  }
  delete[] ppSparsityPattern;
}

#ifdef __cplusplus
}
#endif
