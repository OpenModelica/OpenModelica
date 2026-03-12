/*
 * Stub for ColPackBicoloring_starBicolor when ColPack is not available.
 * The function is declared as external "C" in NBJacobian.mo, so a symbol
 * must exist at link time even if ColPack is not installed.
 */

#include <stdio.h>
#include <stdlib.h>

void ColPackBicoloring_starBicolor(
    int nRows, int nCols,
    const int *rowPtr, const int *colIdx,
    int *colColors, int *nColColors,
    int *rowColors, int *nRowColors)
{
  fprintf(stderr, "ColPackBicoloring_starBicolor: ColPack was not available at build time. "
                  "Bidirectional Jacobian coloring is not supported.\n");
  /* Fall back: assign each column its own color, no row colors */
  *nColColors = nCols;
  *nRowColors = 0;
  for (int i = 0; i < nCols; i++) {
    colColors[i] = i + 1;
  }
  for (int i = 0; i < nRows; i++) {
    rowColors[i] = 0;
  }
}
