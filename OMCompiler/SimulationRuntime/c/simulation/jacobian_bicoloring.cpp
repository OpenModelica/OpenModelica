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

#include "jacobian_util.h"

#ifdef OMC_HAVE_COLPACK
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

    // print sparsity pattern for debugging
    infoStreamPrint(OMC_LOG_JAC, 0, "ColPack star bicoloring: %u rows, %u cols, %u nonzeros", nRows, nCols, rowPtr[nRows]);
    for (unsigned int row = 0; row < nRows; row++) {
      infoStreamPrint(OMC_LOG_JAC, 0, "Row %u: %u nonzeros", row, rowStorage[row][0]);
      for (unsigned int nz = 0; nz < rowStorage[row][0]; nz++) {
        infoStreamPrint(OMC_LOG_JAC, 0, "  Col %u", rowStorage[row][nz + 1]);
      }
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

    // print the colColors and rowColors for debugging
    infoStreamPrint(OMC_LOG_JAC, 0, "ColPack star bicoloring: %u row colors, %u col colors", *nRowColors, *nColColors);
    for (unsigned int row = 0; row < nRows; row++) {
      infoStreamPrint(OMC_LOG_JAC, 0, "Row %u: color %u", row, rowColors[row]);
    }
    for (unsigned int col = 0; col < nCols; col++) {
      infoStreamPrint(OMC_LOG_JAC, 0, "Col %u: color %u", col, colColors[col]);
    }

    return 1;
  } catch (...) {
    return 0;
  }
}