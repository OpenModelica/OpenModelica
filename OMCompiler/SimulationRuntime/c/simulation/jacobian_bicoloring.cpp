/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden.
 *
 * Distributed under the BSD New License, the GNU AGPL version 3, or the
 * OSMC Public License (OSMC-PL) version 1.8.
 */

#include "jacobian_util.h"

#ifdef OMC_RUNTIME_USE_COLPACK
#ifdef TRUE
#undef TRUE
#endif
#ifdef FALSE
#undef FALSE
#endif

#include <ColPackHeaders.h>

#include <vector>
#endif

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
#ifdef OMC_RUNTIME_USE_COLPACK
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
    if (coloring.Bicoloring("DYNAMIC_LARGEST_FIRST", "IMPLICIT_COVERING__STAR_BICOLORING") != _TRUE) {
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
#else
  (void)nRows;
  (void)nCols;
  (void)rowPtr;
  (void)colIdx;
  (void)rowColors;
  (void)nRowColors;
  (void)colColors;
  (void)nColColors;
  return 0;
#endif
}
