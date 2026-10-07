// name:     Array2
// keywords: array
// status:   correct
//
// Multidimensional arrays
//

model Array2
  parameter Integer x[2,3];
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Array2;

// Result:
// class Array2
//   parameter Integer x[1,1];
//   parameter Integer x[1,2];
//   parameter Integer x[1,3];
//   parameter Integer x[2,1];
//   parameter Integer x[2,2];
//   parameter Integer x[2,3];
// end Array2;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
