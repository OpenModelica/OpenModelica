int computeColPackColumnColoring(
	unsigned int nRows,
	unsigned int nCols,
	const unsigned int* leadindex,
	const unsigned int* index,
	unsigned int nnz,
	unsigned int* colorCols,
	unsigned int* maxColors);