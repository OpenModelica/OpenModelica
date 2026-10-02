/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

/*! File jacobian_colpack.cpp
 */

#ifdef OMC_HAVE_COLPACK

#include <ColPackHeaders.h>

#include <limits>
#include <vector>

extern "C" int computeColPackColumnColoring(
    unsigned int nRows,
    unsigned int nCols,
    const unsigned int* leadindex,
    const unsigned int* index,
    unsigned int nnz,
    unsigned int* colorCols,
    unsigned int* maxColors)
{
  if (!leadindex || !colorCols || !maxColors || (nnz > 0 && !index) ||
      nRows > static_cast<unsigned int>(std::numeric_limits<int>::max()) ||
      nCols > static_cast<unsigned int>(std::numeric_limits<int>::max())) {
    return 1;
  }

  try {
    // verification of the input sparsity pattern
    if (leadindex[0] != 0 || leadindex[nCols] != nnz) return 1;

    std::vector<unsigned int> rowNnz(nRows, 0);
    for (unsigned int col = 0; col < nCols; col++) {
      const unsigned int start = leadindex[col];
      const unsigned int end = leadindex[col + 1];
      if (end < start || end > nnz) return 1;

      for (unsigned int nz = start; nz < end; nz++) {
        const unsigned int row = index[nz];
        if (row >= nRows || rowNnz[row] == std::numeric_limits<unsigned int>::max()) {
          return 1;
        }
        rowNnz[row]++;
      }
    }

    // create a row-wise representation of the sparsity pattern for ColPack
    std::vector<std::vector<unsigned int>> rowStorage(nRows);
    std::vector<unsigned int*> sparsity(nRows);
    std::vector<unsigned int> rowOffset(nRows, 0);
    for (unsigned int row = 0; row < nRows; row++) {
      rowStorage[row].resize(rowNnz[row] + 1);
      rowStorage[row][0] = rowNnz[row];
      sparsity[row] = rowStorage[row].data();
    }

    for (unsigned int col = 0; col < nCols; col++) {
      for (unsigned int nz = leadindex[col]; nz < leadindex[col + 1]; nz++) {
        const unsigned int row = index[nz];
        rowStorage[row][rowOffset[row] + 1] = col;
        rowOffset[row]++;
      }
    }

    // run the partial column coloring algorithm
    ColPack::BipartiteGraphPartialColoringInterface coloring(
        SRC_MEM_ADOLC, sparsity.data(), static_cast<int>(nRows), static_cast<int>(nCols));
    if (coloring.PartialDistanceTwoColoring("SMALLEST_LAST", "COLUMN_PARTIAL_DISTANCE_TWO") != _TRUE) {
      return 1; // error case
    }

    std::vector<int> colpackColors;
    coloring.GetRightVertexColors(colpackColors);
    if (colpackColors.size() != nCols) return 1;

    std::vector<unsigned int> colors(nCols);
    unsigned int maxColor = 0;
    for (unsigned int col = 0; col < nCols; col++) {
      const int color = colpackColors[col];
      if (color < 0 || static_cast<unsigned int>(color) >= nCols) return 1;

      colors[col] = static_cast<unsigned int>(color) + 1;
      if (colors[col] > maxColor) maxColor = colors[col];
    }

    for (unsigned int col = 0; col < nCols; col++) colorCols[col] = colors[col];
    *maxColors = maxColor;
    return 0; // success case
  } catch (...) {
    return 1; // error case
  }
}

// Drop this next to computeColPackColumnColoring() in the same translation unit
// (it needs the same includes: <vector>, <limits>, and the ColPack headers).

/**
 * @brief Distance-two row coloring of a CSR sparsity pattern via ColPack.
 *
 * Two rows may share a color only if they have no non-zero column in common.
 * Mirrors computeColPackColumnColoring() but colors the row (left) vertices
 * of the bipartite graph instead of the column (right) vertices.
 *
 * The input here is already row-wise (CSR: leadindex indexed by row, index
 * holding column indices), which is exactly the representation ColPack's
 * ADOLC sparsity format expects -- unlike the column-coloring case, no
 * CSC -> row-wise transposition is needed before handing the pattern over.
 *
 * @param nRows       Number of rows of the matrix (leadindex has nRows + 1 entries).
 * @param nCols       Number of columns of the matrix.
 * @param leadindex   CSR row pointers, size nRows + 1.
 * @param index       CSR column indices, size nnz.
 * @param nnz         Number of non-zeros.
 * @param colorCols   Output: 1-based row color per row, size nRows.
 *                    (Named colorCols to match SPARSE_PATTERN's field, which
 *                    is reused for both column and row coloring elsewhere.)
 * @param maxColors   Output: number of colors used.
 * @return int        0 on success, 1 on error.
 */
extern "C" int computeColPackRowColoring(
    unsigned int nRows,
    unsigned int nCols,
    const unsigned int* leadindex,
    const unsigned int* index,
    unsigned int nnz,
    unsigned int* colorCols,
    unsigned int* maxColors)
{
  if (!leadindex || !colorCols || !maxColors || (nnz > 0 && !index) ||
      nRows > static_cast<unsigned int>(std::numeric_limits<int>::max()) ||
      nCols > static_cast<unsigned int>(std::numeric_limits<int>::max())) {
    return 1;
  }

  try {
    // verification of the input sparsity pattern
    if (leadindex[0] != 0 || leadindex[nRows] != nnz) return 1;

    std::vector<unsigned int> colNnz(nCols, 0);
    for (unsigned int row = 0; row < nRows; row++) {
      const unsigned int start = leadindex[row];
      const unsigned int end = leadindex[row + 1];
      if (end < start || end > nnz) return 1;

      for (unsigned int nz = start; nz < end; nz++) {
        const unsigned int col = index[nz];
        if (col >= nCols || colNnz[col] == std::numeric_limits<unsigned int>::max()) {
          return 1;
        }
        colNnz[col]++;
      }
    }

    // The pattern is already row-wise, so we can build ColPack's per-row
    // ADOLC-style arrays ([rowNnz, col_0, col_1, ...]) directly from it,
    // without the transpose step computeColPackColumnColoring needs.
    std::vector<std::vector<unsigned int>> rowStorage(nRows);
    std::vector<unsigned int*> sparsity(nRows);
    for (unsigned int row = 0; row < nRows; row++) {
      const unsigned int start = leadindex[row];
      const unsigned int end = leadindex[row + 1];
      const unsigned int rowNnz = end - start;

      rowStorage[row].resize(rowNnz + 1);
      rowStorage[row][0] = rowNnz;
      for (unsigned int nz = start; nz < end; nz++) {
        rowStorage[row][1 + (nz - start)] = index[nz];
      }
      sparsity[row] = rowStorage[row].data();
    }

    // run the partial row coloring algorithm
    ColPack::BipartiteGraphPartialColoringInterface coloring(
        SRC_MEM_ADOLC, sparsity.data(), static_cast<int>(nRows), static_cast<int>(nCols));
    if (coloring.PartialDistanceTwoColoring("SMALLEST_LAST", "ROW_PARTIAL_DISTANCE_TWO") != _TRUE) {
      return 1; // error case
    }

    std::vector<int> colpackColors;
    coloring.GetLeftVertexColors(colpackColors);
    if (colpackColors.size() != nRows) return 1;

    std::vector<unsigned int> colors(nRows);
    unsigned int maxColor = 0;
    for (unsigned int row = 0; row < nRows; row++) {
      const int color = colpackColors[row];
      if (color < 0 || static_cast<unsigned int>(color) >= nRows) return 1;

      colors[row] = static_cast<unsigned int>(color) + 1;
      if (colors[row] > maxColor) maxColor = colors[row];
    }

    for (unsigned int row = 0; row < nRows; row++) colorCols[row] = colors[row];
    *maxColors = maxColor;
    return 0; // success case
  } catch (...) {
    return 1; // error case
  }
}

extern "C" int computeColPackStarBicoloring(
    unsigned int nRows,
    unsigned int nCols,
    const unsigned int* rowPtr,
    const unsigned int* colIdx,
    unsigned int* rowColors,
    unsigned int* nRowColors,
    unsigned int* colColors,
    unsigned int* nColColors)
{
  if (!rowPtr || !rowColors || !nRowColors || !colColors || !nColColors) return 0;
  if (rowPtr[nRows] > 0 && !colIdx) return 0;

  try {
    std::vector<std::vector<unsigned int>> rowStorage(nRows);
    std::vector<unsigned int*> sparsity(nRows);
    for (unsigned int row = 0; row < nRows; row++) {
      const unsigned int start = rowPtr[row];
      const unsigned int end = rowPtr[row + 1];
      if (end < start) return 0;
      const unsigned int rowNnz = end - start;
      rowStorage[row].resize(rowNnz + 1);
      rowStorage[row][0] = rowNnz;
      for (unsigned int nz = 0; nz < rowNnz; nz++) {
        if (colIdx[start + nz] >= nCols) return 0;
        rowStorage[row][nz + 1] = colIdx[start + nz];
      }
      sparsity[row] = rowStorage[row].data();
    }

    ColPack::BipartiteGraphBicoloringInterface coloring(
        SRC_MEM_ADOLC, sparsity.data(), static_cast<int>(nRows), static_cast<int>(nCols));
    if (coloring.Bicoloring("LARGEST_FIRST", "IMPLICIT_COVERING__STAR_BICOLORING") != _TRUE) {
      return 0;
    }

    std::vector<int> leftColors;
    std::vector<int> rightColors;
    coloring.GetLeftVertexColors(leftColors);
    coloring.GetRightVertexColors_Transformed(rightColors);

    unsigned int maxRowColor = 0;
    unsigned int maxColColor = 0;
    for (unsigned int row = 0; row < nRows; row++) {
      const int color = row < leftColors.size() ? leftColors[row] : 0;
      rowColors[row] = color > 0 ? static_cast<unsigned int>(color) : 0;
      if (rowColors[row] > maxRowColor) maxRowColor = rowColors[row];
    }
    for (unsigned int col = 0; col < nCols; col++) {
      const int color = col < rightColors.size() ? rightColors[col] : 0;
      colColors[col] = color > 0 ? static_cast<unsigned int>(color) : 0;
      if (colColors[col] > maxColColor) maxColColor = colColors[col];
    }
    *nRowColors = maxRowColor;
    *nColColors = maxColColor;

    return 1;
  } catch (...) {
    return 0;
  }
}



#endif
