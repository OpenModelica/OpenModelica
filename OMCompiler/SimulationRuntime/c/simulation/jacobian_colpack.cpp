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
#endif
